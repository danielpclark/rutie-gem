require 'rake'
require 'rbconfig'

class Rutie
  # Rake tasks that build a Rutie extension so `ruby` can load it:
  #
  #   # Rakefile
  #   require 'rutie/rake_task'
  #   Rutie::RakeTask.new
  #
  #   Rake::TestTask.new(test: 'rutie:build') { |t| ... }
  #
  # `rutie:build` runs `cargo build --release`. On macOS it builds with
  # `NO_LINK_RUTIE=1` and `-undefined dynamic_lookup` instead, so the extension
  # uses the libruby of the `ruby` process loading it rather than linking its
  # own (with a static Ruby that would be a second VM that never booted).
  # `rutie:clean` runs `cargo clean`.
  class RakeTask
    include Rake::DSL

    # `release: false` builds the debug profile, for `Rutie.new(..., release: 'debug')`.
    # `cargo_args` are extra arguments for cargo, such as `%w[--features foo]`.
    def initialize(release: true, cargo_args: [], os: nil)
      @release = release
      @cargo_args = cargo_args
      @os = os # for testing purposes

      define_tasks
    end

    # The environment and command `rutie:build` runs.
    def build_command
      profile = @release ? ['--release'] : []

      if macos?
        [{ 'NO_LINK_RUTIE' => '1' },
         'cargo', 'rustc', *profile, *@cargo_args, '--', '-C', 'link-args=-Wl,-undefined,dynamic_lookup']
      else
        [{}, 'cargo', 'build', *profile, *@cargo_args]
      end
    end

    private
    def define_tasks
      namespace :rutie do
        desc 'Build the Rust extension'
        task(:build) { sh(*build_command) }

        desc 'Remove the Rust build output (cargo clean)'
        task(:clean) { sh 'cargo', 'clean' }
      end
    end

    def macos?
      (@os || RbConfig::CONFIG['host_os']) =~ /darwin|mac os/
    end
  end
end
