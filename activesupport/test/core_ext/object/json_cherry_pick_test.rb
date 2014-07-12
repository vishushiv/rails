require 'abstract_unit'

# These test cases were added to test that cherry-picking the json extensions
# works correctly, primarily for dependencies problems such as #16131. They need
# to be executed in isolation to reproduce the scenario correctly, because other
# test cases might have already required or auto-loaded additional dependencies.

if Process.respond_to?(:fork)
  class JsonCherryPickTest < ActiveSupport::TestCase
    def test_time_as_json

      within_new_process do
        require 'active_support'
        require 'active_support/core_ext/object/json'

        current_time  = Time.now
        round_tripped = Time.parse(current_time.as_json)

        # We loose some (sub-second) precision when roundtripping via JSON, so
        # we have to truncate them for the comparasion to work reliably
        assert_equal current_time.to_i, round_tripped.to_i
      end
    end

    def test_date_as_json
      within_new_process do
        require 'active_support'
        require 'active_support/core_ext/object/json'

        current_date  = Date.today
        round_tripped = Date.parse(current_date.as_json)

        assert_equal current_date, round_tripped
      end
    end

    def test_datetime_as_json
      within_new_process do
        require 'active_support'
        require 'active_support/core_ext/object/json'

        current_datetime = DateTime.now
        round_tripped    = DateTime.parse(current_datetime.as_json)

        # We loose some (sub-second) precision when roundtripping via JSON, so
        # we have to truncate them for the comparasion to work reliably
        assert_equal current_datetime.to_i, round_tripped.to_i
      end
    end

    private
      def within_new_process(&block)
        rd, wr = IO.pipe
        rd.binmode
        wr.binmode

        pid = fork do
          rd.close

          begin
            block.call
          rescue Exception => e
            wr.write Marshal.dump(e)
          ensure
            wr.close
            exit!
          end
        end

        wr.close

        Process.waitpid pid

        data = rd.read

        raise Marshal.load(data) unless data.empty?
      end
  end
end
