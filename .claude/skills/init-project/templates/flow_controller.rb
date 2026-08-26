# Reads requirements.md and turns it into something a browser can show:
# the brief (goal, cuts, success criterion), the primary path, and — only when the
# team asked for them — a data model, states or scenarios.
#
# requirements.md stays the single source of truth. Nothing is cached, nothing is
# duplicated, so the page cannot drift from the requirement.
#
# ON FORGIVINGNESS: an earlier version silently dropped half the path when the
# agent wrote a dotted arrow or a text label — forgiving toward the agent, not
# toward the team. Now arrows are normalised first, and whatever still does not
# parse is reported on the page. A page that shows less than the truth without
# saying so is worse than no page.
class FlowController < ApplicationController
  # Any mermaid node shape: A[x] A{x} A(x) A([x]) A((x)) A[[x]]
  SHAPE = /(\w+)\s*[\[({]{1,2}([^\]\)}]+)[\])}]{1,2}/
  EDGE  = /(\w+)\s*-->\s*(?:\|([^|]*)\|\s*)?(\w+)/
  STATE = /(\[\*\]|\w+)\s*-->\s*(\[\*\]|\w+)\s*(?::\s*(.+))?/
  ENTITY = /(\w+)\s+([|}o{<>.-]{4,})\s+(\w+)\s*:\s*"?([^"\n]*)"?/
  GHERKIN = /^\s*(Szenario|Scenario|Gegeben|Given|Wenn|When|Dann|Then|Und|And|Aber|But)\b[:\s]*(.*)$/
  FENCE = /```(\w+)?\n(.*?)```/m
  DONE = %w[fertig done built erledigt gebaut].freeze

  CARDINALITY = {
    "||--o{" => "1 : n", "||--|{" => "1 : n", "||--||" => "1 : 1",
    "}o--o{" => "n : m", "}|--|{" => "n : m", "|o--o|" => "0..1 : 0..1"
  }.freeze

  def index
    @demo      = section("The Demo")
    @who       = section("Who it is for")
    @hurts     = section("What hurts today")
    @goal      = section("Goal")
    @owner     = section("Users & Ownership")
    @out       = section("Explicitly OUT of scope")
    @criterion = section("Demo Success Criterion")
    @changed   = requirements.exist? ? ago(requirements.mtime) : nil
    @tests     = last_test_run

    blocks = source.scan(FENCE).map { |lang, body| [lang.to_s, body.to_s] }
    main   = blocks.index { |lang, body| lang == "mermaid" && body.include?("flowchart") }

    if main
      @steps, @branches, @unread = flow(blocks[main][1])
      blocks.delete_at(main)
    else
      @steps, @branches, @unread = [], [], 0
    end

    @examples  = examples(@steps)
    @first_open = @steps.index { |s| !s[:done] }&.+(1)

    @extras, @unshown = [], []
    blocks.each do |lang, body|
      drawn = extra(lang, body)
      drawn ? @extras << drawn : @unshown << kind(lang, body)
    end
  end

  private

  def requirements = Rails.root.join("requirements.md")

  # Computed here rather than via time_ago_in_words: that helper follows the app
  # locale, which is English by default, and half a German sentence in English is
  # exactly the detail that makes a page look untended.
  def ago(time)
    minutes = ((Time.current - time) / 60).floor
    return "gerade eben"                      if minutes < 1
    return "vor einer Minute"                 if minutes == 1
    return "vor #{minutes} Minuten"           if minutes < 60

    hours = minutes / 60
    return "vor einer Stunde"                 if hours == 1
    return "vor #{hours} Stunden"             if hours < 24

    days = hours / 24
    days == 1 ? "seit gestern" : "vor #{days} Tagen"
  end

  def source
    requirements.exist? ? requirements.read : ""
  rescue StandardError
    ""
  end

  # The last test run, read from the file RSpec already writes after every run —
  # no gem, no second run, no coverage tooling. It answers the one question this
  # page could not: "läuft mein Projekt noch?"
  #
  # Deliberately not a percentage. Coverage needs a gem the README rules out, and
  # "62 %" is uninterpretable for the people this page is for — it would be a
  # second flattering number beside a counter that already flatters.
  def last_test_run
    file = Rails.root.join("spec/examples.txt")
    return nil unless file.exist?

    rows   = file.readlines.grep(/\|\s*(passed|failed|pending)\s*\|/)
    failed = rows.count { |r| r.include?("| failed") }
    { total: rows.size, failed: failed, when: ago(file.mtime) }
  rescue StandardError
    nil
  end

  # One markdown section, or nil when it is missing or still a placeholder.
  def section(heading)
    body = source[/^##\s+#{Regexp.escape(heading)}[^\n]*\n(.*?)(?=\n##\s|\z)/m, 1].to_s
    body = body.gsub(/```.*?```/m, "").strip
    return nil if body.blank? || body.include?("PLACEHOLDER")

    body
  end

  # --- the main path -------------------------------------------------------

  def flow(block)
    done  = marks(block)
    clean = normalise(block.gsub(/:::\w+/, ""))

    nodes = clean.scan(SHAPE).to_h
    parts, inner = subgraphs(clean)

    bare  = clean.gsub(SHAPE) { Regexp.last_match(1) }
    edges = bare.scan(EDGE).map { |from, label, to| [from, label.to_s.strip, to] }
    path  = walk(edges)

    steps = path.map do |id|
      label, line_break = (nodes[id] || id).split(%r{<br\s*/?>}, 2)
      detail = [line_break, parts[id]].compact_blank.join(" · ")
      { id: id, label: label.strip, detail: detail.presence, done: done.include?(id) }
    end
    steps = [] if steps.any? { |s| s[:label].include?("PLACEHOLDER") }

    covered = path.each_cons(2).to_a
    extra   = edges.reject { |from, _, to| covered.include?([from, to]) }

    # Each branch carries the step number it leaves from. Listed on its own the
    # reader had to match a label back against the path by eye; with the number it
    # reads as what it is — a second way out of one of these boxes.
    branches = extra.map do |from, label, to|
      { step: path.index(from)&.+(1), from: nodes[from] || from,
        label: label, to: nodes[to] || to }
    end

    # Orphans, not syntax: any node the team wrote down that ends up on neither the
    # path nor a branch has been dropped. Counting the outcome rather than the
    # spelling catches connectors nobody anticipated — including the next one.
    shown  = (path + extra.flat_map { |from, _, to| [from, to] }).uniq
    orphan = nodes.keys - shown - inner

    [steps, branches, orphan.size]
  end

  # A subgraph is mermaid's way of saying "this step has parts". Its inner nodes
  # become the SECOND LINE of the parent box, not a second level of boxes.
  #
  # Two levels would mean two counters and two markers to keep true, and the
  # marker is already the weakest link — it is Claude's own word, nobody checks
  # it. One level with a detail line costs nothing and reads in one glance,
  # which is the only property this row has.
  #
  # Before this, inner nodes had no edges, so they were reported as dropped
  # steps: writing ordinary mermaid produced a red alarm.
  def subgraphs(block)
    parts   = {}
    inner   = []
    current = nil

    block.each_line do |line|
      if (m = line.match(/^\s*subgraph\s+(\w+)/))
        current = m[1]
        parts[current] = []
      elsif current && line.match?(/^\s*end\s*$/)
        current = nil
      elsif current
        line.scan(SHAPE) do |id, label|
          parts[current] << label
          inner << id
        end
      end
    end

    [parts.transform_values { |v| v.join(" · ").presence }.compact, inner]
  end

  # Every mermaid arrow spelling becomes "A -->|label| B" before anything is read.
  # Order matters: the labelled forms have to go first, or the plain ones eat them.
  def normalise(block)
    block
      .gsub(/-\.\s*([^.>|\n]+?)\s*\.->/) { "-->|#{Regexp.last_match(1)}|" }  # -.label.->
      .gsub(/-\.-*>/, "-->")                                                # -.->
      .gsub(/=+\s*([^=>|\n]+?)\s*=+>/) { "-->|#{Regexp.last_match(1)}|" }    # ==label==>
      .gsub(/={2,}>/, "-->")                                                # ==>
      .gsub(/--\s*([^->|\n]+?)\s*-{2,}>/) { "-->|#{Regexp.last_match(1)}|" } # -- label -->
      .gsub(/-{2,}>/, "-->")                                                # ---> etc.
  end

  def marks(block)
    ids = block.scan(/(\w+)\s*[\[({][^\])}]+[\])}]:::(\w+)/)
               .select { |_, name| name.downcase.in?(DONE) }.map(&:first)
    block.scan(/^\s*class\s+([\w,\s]+?)\s+(\w+)\s*$/) do |list, name|
      ids.concat(list.split(",").map(&:strip)) if name.downcase.in?(DONE)
    end
    ids.uniq
  end

  def walk(edges)
    return [] if edges.empty?

    targets = edges.map(&:last)
    start   = edges.map(&:first).find { |id| targets.exclude?(id) } || edges.first.first
    longest(start, edges, [])
  end

  # The main path is the LONGEST way through, not the first one written down.
  # Following the first outgoing edge made an error branch the main path whenever
  # the agent happened to note it before the happy one — the diagram looked right
  # in the file and wrong on the screen. Ten nodes at most, so brute force is free.
  def longest(node, edges, visited)
    seen = visited + [node]
    # Unlabelled edges first: a label like |abgelehnt| marks a condition, so the
    # plain edge is the main line. Without this tiebreak two equally long ways out
    # of one node are decided by writing order, and the error branch can win.
    nexts = edges.select { |from, _, to| from == node && seen.exclude?(to) }
                 .sort_by { |_, label, _| label.present? ? 1 : 0 }
                 .map(&:last)
    return seen if nexts.empty?

    nexts.map { |n| longest(n, edges, seen) }.max_by(&:size)
  end

  # The sentences printed under the path. They MUST be built from this project's
  # own steps: the design page works because "brand-600" is really on the screen,
  # and an example pointing at a step that does not exist teaches distrust of the
  # page rather than the phrasing.
  #
  # Which is also why there are two of them below three steps. "Streich den
  # letzten Schritt" is advice on a six-step path and nonsense on a two-step one,
  # and an example that recommends deleting half the app is worse than no example.
  def examples(steps)
    return [] if steps.size < 2

    out = [
      "„Zwischen Schritt 1 und 2 fehlt: …\u201C — also zwischen \u201E#{steps[0][:label]}\u201C und \u201E#{steps[1][:label]}\u201C."
    ]

    rename = steps.size >= 3 ? steps[steps.size / 2] : steps[1]
    out << "„Schritt #{steps.index(rename) + 1} heißt bei uns nicht \u201E#{rename[:label]}\u201C — das ist …\u201C"

    if steps.size >= 3
      out << "„Schritt #{steps.size} brauchen wir nicht. Streich \u201E#{steps.last[:label]}\u201C.\u201C"
    end

    out
  end

  # --- what the team asked for on top --------------------------------------
  #
  # No catch-all: a block this page cannot draw is not lifted onto the screen as if
  # it belonged there, or any stray snippet becomes a card of equal standing.
  #
  # But it is not swallowed either. Dropping the catch-all traded a noisy failure
  # for a silent one — a `journey` or a `sequenceDiagram` simply vanished. Whatever
  # cannot be drawn is counted and named, so the team knows the page is not the
  # whole file.

  def extra(lang, body)
    return states(body)    if lang == "mermaid" && body.include?("stateDiagram")
    return entities(body)  if lang == "mermaid" && body.include?("erDiagram")
    return scenarios(body) if lang.in?(%w[gherkin feature cucumber]) || body.match?(GHERKIN)

    nil
  end

  # What to call a block we cannot draw. For mermaid that is its first word, which
  # is the diagram type; otherwise the fence language.
  def kind(lang, body)
    type = body[/\A\s*(\w+)/, 1]
    return type if lang == "mermaid" && type.present?

    lang.presence || "ohne Typ"
  end

  def states(body)
    rows = body.scan(STATE).map { |from, to, label| [pretty(from), label.to_s.strip, pretty(to)] }
    return nil if rows.empty?

    { title: "Zustände", kind: :rows, rows: rows,
      hint: "Jeder Zustand ist ein Feld am Datensatz und mindestens ein Test." }
  end

  def pretty(id) = id == "[*]" ? "Start / Ende" : id.to_s.humanize

  def entities(body)
    rows = body.scan(ENTITY).map do |left, symbol, right, label|
      ["#{left.humanize} #{CARDINALITY.fetch(symbol, symbol)} #{right.humanize}", label.to_s.strip, nil]
    end
    return nil if rows.empty?

    { title: "Datenmodell", kind: :rows, rows: rows,
      hint: "Jede Beziehung ist eine Migration und eine Regel, wer was sehen darf." }
  end

  def scenarios(body)
    lines = body.lines.filter_map do |line|
      next unless (m = line.match(GHERKIN))

      [m[1], m[2].to_s.strip]
    end
    return nil if lines.empty?

    { title: "Szenarien", kind: :gherkin, lines: lines,
      hint: "Jedes Szenario lässt sich eins zu eins in einen Test übersetzen." }
  end
end
