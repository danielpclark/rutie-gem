require 'test_helper'
require 'rutie/rake_task'

class RutieRakeTaskTest < Minitest::Test
  def setup
    @saved_application = Rake.application
    Rake.application = Rake::Application.new
  end

  def teardown
    Rake.application = @saved_application
  end

  def test_linux_builds_with_cargo_build
    task = Rutie::RakeTask.new(os: 'linux-gnu')

    assert_equal [{}, 'cargo', 'build', '--release'], task.build_command
  end

  def test_macos_builds_without_linking_libruby
    task = Rutie::RakeTask.new(os: 'darwin23')

    assert_equal [{ 'NO_LINK_RUTIE' => '1' }, 'cargo', 'rustc', '--release', '--',
                  '-C', 'link-args=-Wl,-undefined,dynamic_lookup'], task.build_command
  end

  def test_debug_profile_and_extra_cargo_args
    task = Rutie::RakeTask.new(release: false, cargo_args: %w[--features foo], os: 'mingw32')

    assert_equal [{}, 'cargo', 'build', '--features', 'foo'], task.build_command
  end

  def test_defines_build_and_clean_tasks
    Rutie::RakeTask.new(os: 'linux-gnu')

    assert Rake::Task.task_defined?('rutie:build')
    assert Rake::Task.task_defined?('rutie:clean')
  end
end
