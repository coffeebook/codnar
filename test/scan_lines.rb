require "codnar"
require "olag/test"
require "test/spec"

# Test scanning classified lines.
class TestScanLines < Test::Unit::TestCase

  include Test::WithErrors
  include Test::WithFakeFS

  def test_scan_lines
    write_fake_file("comments", INPUT)
    scanner = Codnar::Scanner.new(@errors, SYNTAX)
    scanner.lines("comments").should == LINES
    @errors.should == ERRORS
  end

  SYNTAX = {
    "start_state" => "comment",
    "patterns" => {
      "shell" => {
        "regexp" => "^(\\s*)#+\\s*(.*)$",
        "groups" => [ "indentation", "payload" ],
        "kind" => "comment",
      },
      "c++" => {
        "regexp" => /^(\s*)\/\/+\s*(.*)$/,
        "groups" => [ "indentation", "payload" ],
        "kind" => "comment",
      },
      "invalid" => { "regexp" => "(" },
    },
    "states" => {
      "comment" => {
        "transitions" => [
          { "pattern" => "shell" },
          { "pattern" => "c++" },
          { "pattern" => "no-such-pattern", "next_state" => "no-such-state" },
        ],
      },
    },
  }

  INPUT = <<-EOF.unindent.gsub("#!", "#")
    #! foo
     // bar
      baz
  EOF

  LINES = [ {
    "kind" => "comment",
    "line" => "# foo",
    "indentation" => "",
    "payload" => "foo",
    "number" => 1,
  }, {
    "kind" => "comment",
    "line" => " // bar",
    "indentation" => " ",
    "payload" => "bar",
    "number" => 2,
  }, {
    "kind" => "error",
    "line" => "  baz",
    "indentation" => "  ",
    "payload" => "baz",
    "state" => "comment",
    "number" => 3,
  } ]

  ERRORS = [
    "#{$0}: Invalid pattern: invalid regexp: ( error: premature end of regular expression: /(/",
    "#{$0}: Reference to a missing pattern: no-such-pattern",
    "#{$0}: Reference to a missing state: no-such-state",
    "#{$0}: State: comment failed to classify line: baz in file: comments at line: 3"
  ]

end
