require "test_with_tempfile"

module Codnar

  # Tests with configurations. Requires also including TestWithTempfile.
  module TestWithConfigurations

    # Test running the Splitter with merged configurations.
    def check_split_file(file_text, *configurations, &block)
      configuration = configurations.inject({}) do |merged_configuration, next_configuration|
        merged_configuration.deep_merge(next_configuration)
      end
      splitter = Splitter.new(@errors, configuration)
      chunks = splitter.chunks(path = write_tempfile("splitted", file_text))
      @errors.should == []
      chunks.should == yield(path)
    end

  end

end
