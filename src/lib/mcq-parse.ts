// Parse MCQ blocks from raw text into a structured form.
// Supported per-block shape (flexible whitespace + labels):
//   Q: What is audit?
//   A. Option A
//   B. Option B
//   C. Option C
//   D. Option D
//   Answer: B
//   Explanation: ...
//
// Accepted variants:
//   - "Q:", "Q.", "Q)", "Question:", "1.", "1)" for the question line
//   - "A.", "A)", "(A)", "a." for options
//   - "Answer:", "Ans:", "Correct:" for the answer (letter A-D or full option text)
//   - "Explanation:", "Explain:", "Solution:" for the explanation
//   - Blocks separated by blank lines or detected by a new Q-line

export type ParsedMcq = {
  question: string;
  question_type: "mcq" | "true_false";
  option_a: string;
  option_b: string;
  option_c: string;
  option_d: string;
  correct_option: "A" | "B" | "C" | "D";
  explanation: string;
};

export type ParsedMcqResult = {
  cards: ParsedMcq[];
  invalidBlocks: { raw: string; reason: string }[];
};

const norm = (s: string) => s.replace(/\s+/g, " ").trim();

function splitBlocks(text: string): string[] {
  const t = text.replace(/\r\n?/g, "\n").trim();
  if (!t) return [];
  // Split on blank lines first; if that produces only 1 block, also split on the
  // next "Q:"/numbered question marker.
  const byBlank = t
    .split(/\n\s*\n+/)
    .map((b) => b.trim())
    .filter(Boolean);
  if (byBlank.length > 1) return byBlank;
  const re = /(?=^\s*(?:q\s*[:.\)\-]|question\s*[:.\)\-]|\d+\s*[.\)]))/gim;
  return t
    .split(re)
    .map((b) => b.trim())
    .filter(Boolean);
}

function parseBlock(raw: string): { mcq: ParsedMcq | null; reason?: string } {
  const lines = raw
    .split("\n")
    .map((l) => l.trim())
    .filter(Boolean);
  if (lines.length < 2) return { mcq: null, reason: "Too few lines for a question" };

  // True/False detection: leading marker like "TF:", "TRUE_FALSE:", "T/F:"
  const tfHead = lines[0].match(/^\s*(?:tf|true[_\s/-]?false|t\/f)\s*[:.\)\-]\s*(.+)$/i);
  if (tfHead) {
    const tfQuestion = norm(
      tfHead[1] +
        " " +
        lines
          .slice(1)
          .filter(
            (l) =>
              !/^\s*(?:answer|ans|correct|explanation|explain|solution|reason|a|b)\s*[:.\)\-]/i.test(
                l,
              ),
          )
          .join(" "),
    );
    let tfAnswer: string | null = null;
    let tfExp = "";
    for (const line of lines.slice(1)) {
      const ans = line.match(/^\s*(?:answer|ans|correct(?:\s+answer)?)\s*[:.\-)]\s*(.+)$/i);
      const exp = line.match(/^\s*(?:explanation|explain|solution|reason)\s*[:.\-)]\s*(.*)$/i);
      if (ans) tfAnswer = ans[1].trim();
      else if (exp) tfExp = exp[1].trim();
    }
    if (!tfAnswer) return { mcq: null, reason: "True/False missing answer" };
    const a = tfAnswer.toLowerCase().replace(/[^a-z]/g, "");
    const correct: "A" | "B" =
      a === "true" || a === "t" || a === "a"
        ? "A"
        : a === "false" || a === "f" || a === "b"
          ? "B"
          : "A";
    if (!["true", "t", "a", "false", "f", "b"].includes(a))
      return { mcq: null, reason: `Could not resolve True/False answer "${tfAnswer}"` };
    return {
      mcq: {
        question: tfQuestion.slice(0, 4000),
        question_type: "true_false",
        option_a: "True",
        option_b: "False",
        option_c: "",
        option_d: "",
        correct_option: correct,
        explanation: norm(tfExp).slice(0, 4000),
      },
    };
  }

  if (lines.length < 5) return { mcq: null, reason: "Too few lines for an MCQ" };

  const opts: Record<"A" | "B" | "C" | "D", string | null> = { A: null, B: null, C: null, D: null };
  let answer: string | null = null;
  let explanation = "";
  const qParts: string[] = [];
  let phase: "question" | "options" | "tail" = "question";

  for (const line of lines) {
    const optMatch = line.match(/^\s*[(\[]?\s*([A-Da-d])\s*[)\].:\-]\s+(.*)$/);
    const ansMatch = line.match(/^\s*(?:answer|ans|correct(?:\s+answer)?)\s*[:.\-)]\s*(.+)$/i);
    const expMatch = line.match(/^\s*(?:explanation|explain|solution|reason)\s*[:.\-)]\s*(.*)$/i);
    const qMatch =
      line.match(/^\s*(?:q|question)\s*[:.)\-]\s*(.+)$/i) || line.match(/^\s*\d+\s*[.)]\s*(.+)$/);

    if (ansMatch) {
      answer = ansMatch[1].trim();
      phase = "tail";
      continue;
    }
    if (expMatch) {
      explanation = expMatch[1].trim();
      phase = "tail";
      continue;
    }
    if (optMatch) {
      const k = optMatch[1].toUpperCase() as "A" | "B" | "C" | "D";
      opts[k] = norm(optMatch[2]);
      phase = "options";
      continue;
    }
    if (qMatch && phase === "question" && qParts.length === 0) {
      qParts.push(qMatch[1]);
      continue;
    }
    if (phase === "question") qParts.push(line);
    else if (phase === "tail" && explanation) explanation += " " + line;
  }

  const question = norm(qParts.join(" "));
  if (!question) return { mcq: null, reason: "Missing question text" };
  if (!opts.A || !opts.B || !opts.C || !opts.D) return { mcq: null, reason: "Need 4 options A–D" };
  if (!answer) return { mcq: null, reason: "Missing answer" };

  // Resolve answer → letter
  let correct: "A" | "B" | "C" | "D" | null = null;
  const letter = answer.trim().match(/^[(\[]?([A-Da-d])[)\].:]?$/);
  if (letter) {
    correct = letter[1].toUpperCase() as "A" | "B" | "C" | "D";
  } else {
    const a = norm(answer).toLowerCase();
    for (const k of ["A", "B", "C", "D"] as const) {
      if (opts[k] && norm(opts[k]!).toLowerCase() === a) {
        correct = k;
        break;
      }
    }
  }
  if (!correct) return { mcq: null, reason: `Could not resolve answer "${answer}"` };

  return {
    mcq: {
      question: question.slice(0, 4000),
      question_type: "mcq",
      option_a: opts.A.slice(0, 1000),
      option_b: opts.B.slice(0, 1000),
      option_c: opts.C.slice(0, 1000),
      option_d: opts.D.slice(0, 1000),
      correct_option: correct,
      explanation: norm(explanation).slice(0, 4000),
    },
  };
}

export function parseMcqText(input: string): ParsedMcqResult {
  const blocks = splitBlocks(input ?? "");
  const cards: ParsedMcq[] = [];
  const invalidBlocks: { raw: string; reason: string }[] = [];
  for (const b of blocks) {
    const { mcq, reason } = parseBlock(b);
    if (mcq) cards.push(mcq);
    else invalidBlocks.push({ raw: b, reason: reason ?? "Unparseable" });
  }
  return { cards, invalidBlocks };
}

/** Normalize a question for duplicate detection. */
export function fingerprintQuestion(q: string): string {
  return q
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, " ")
    .trim();
}
