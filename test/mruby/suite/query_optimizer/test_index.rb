class TestIndex < QueryOptimizerTestCase
  def setup
    Groonga::Schema.define do |schema|
      schema.create_table("Logs") do |table|
        table.text("message")
      end

      schema.create_table("Terms",
                          :type => :patricia_trie,
                          :default_tokenizer => "TokenBigram",
                          :normalizer => "NormalizerAuto") do |table|
        table.index("Logs", "message")
      end
    end

    @logs = Groonga["Logs"]
    setup_expression(@logs)
  end

  def teardown
    teardown_expression
  end

  def test_match
    assert_equal(<<-DUMP, dump_plan("message @ 'Groonga'"))
[0]
  op:         <match>
  logical_op: <or>
  query:      <"Groonga">
  expr:       <0..2>
    DUMP
  end

  def test_with_arithmetic_operator
    assert_equal(<<-DUMP, dump_plan("message @ 'Groonga' && ((1 + 1) == 2)"))
[0]
  op:         <match>
  logical_op: <or>
  query:      <"Groonga">
  expr:       <0..2>
[1]
  op:         <equal>
  logical_op: <and>
  query:      <2>
  expr:       <3..7>
    DUMP
  end
end
