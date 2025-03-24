# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `toys` gem.
# Please instead update this file by running `bin/tapioca gem toys`.


# Toys is a configurable command line tool. Write commands in config files
# using a simple DSL, and Toys will provide the command line executable and
# take care of all the details such as argument parsing, online help, and error
# reporting. Toys is designed for software developers, IT professionals, and
# other power users who want to write and organize scripts to automate their
# workflows. It can also be used as a Rake replacement, providing a more
# natural command line interface for your project's build tasks.
#
# This set of documentation includes classes from both Toys-Core, the
# underlying command line framework, and the Toys executable itself. Most of
# the actual classes you will likely need to look up are from Toys-Core.
#
# ## Common starting points
#
# * For information on the DSL used to write tools, start with
#   {Toys::DSL::Tool}.
# * The base class for tool runtime (i.e. that defines the basic methods
#   available to a tool's implementation) is {Toys::Context}.
# * For information on writing mixins, see {Toys::Mixin}.
# * For information on writing templates, see {Toys::Template}.
# * For information on writing acceptors, see {Toys::Acceptor}.
# * For information on writing custom shell completions, see {Toys::Completion}.
# * Standard mixins are defined under the {Toys::StandardMixins} module.
# * Various utilities are defined under {Toys::Utils}. Some of these serve as
#   the implementations of corresponding mixins.
#
# source://toys//lib/toys/version.rb#3
module Toys
  class << self
    # source://toys-core/0.15.6/lib/toys/dsl/base.rb#28
    def Tool(*args, name: T.unsafe(nil), base: T.unsafe(nil)); end

    # source://toys-core/0.15.6/lib/toys-core.rb#114
    def executable_path; end

    # source://toys-core/0.15.6/lib/toys-core.rb#114
    def executable_path=(_arg0); end
  end
end

# Path to the Toys executable.
#
# @return [String] Absolute path to the executable
# @return [nil] if the Toys executable is not running.
#
# source://toys//lib/toys.rb#59
Toys::EXECUTABLE_PATH = T.let(T.unsafe(nil), String)

# @private
#
# source://toys//lib/toys.rb#64
Toys::LIB_PATH = T.let(T.unsafe(nil), String)

# Subclass of `Toys::CLI` configured for the behavior of the standard Toys
# executable. Specifically, this subclass:
#
# * Configures the standard names of files and directories, such as the
#   `.toys.rb` file for an "index" tool, and the `.data` and `.lib` directory
#   names.
# * Configures default descriptions for the root tool.
# * Configures a default error handler and logger that provide ANSI-colored
#   formatted output.
# * Configures a set of middleware that implement online help, verbosity
#   flags, and other features.
# * Provides a set of standard templates for typical project build and
#   maintenance scripts (suh as clean, test, and rubocop).
# * Finds tool definitions in the standard Toys search path.
#
# source://toys//lib/toys/standard_cli.rb#20
class Toys::StandardCLI < ::Toys::CLI
  # Create a standard CLI, configured with the appropriate paths and
  # middleware.
  #
  # @param custom_paths [String, Array<String>] Custom paths to use. If set,
  #   the CLI uses only the given paths. If not, the CLI will search for
  #   paths from the current directory and global paths.
  # @param include_builtins [boolean] Add the builtin tools. Default is true.
  # @param cur_dir [String, nil] Starting search directory for configs.
  #   Defaults to the current working directory.
  # @return [StandardCLI] a new instance of StandardCLI
  #
  # source://toys//lib/toys/standard_cli.rb#115
  def initialize(custom_paths: T.unsafe(nil), include_builtins: T.unsafe(nil), cur_dir: T.unsafe(nil)); end

  private

  # Add paths for builtin tools
  #
  # source://toys//lib/toys/standard_cli.rb#147
  def add_builtins; end

  # Add paths for the given current directory and its ancestors, plus the
  # global paths.
  #
  # @param cur_dir [String] The starting directory path, or nil to use the
  #   current directory
  # @return [self]
  #
  # source://toys//lib/toys/standard_cli.rb#161
  def add_current_directory_paths(cur_dir); end

  # Returns the default set of global config directories.
  #
  # @return [Array<String>]
  #
  # source://toys//lib/toys/standard_cli.rb#194
  def default_global_dirs; end

  # Returns the middleware for the standard Toys CLI.
  #
  # @return [Array]
  #
  # source://toys//lib/toys/standard_cli.rb#209
  def default_middleware_stack; end

  # Returns a ModuleLookup for the default templates.
  #
  # @return [Toys::ModuleLookup]
  #
  # source://toys//lib/toys/standard_cli.rb#240
  def default_template_lookup; end

  # Step out of any toys dir.
  #
  # @param dir [String] The starting path
  # @param toys_dir_name [String] The name of the toys directory to look for
  # @return [String] The final directory path
  #
  # source://toys//lib/toys/standard_cli.rb#176
  def skip_toys_dir(dir, toys_dir_name); end
end

# Standard toys configuration directory name.
#
# @return [String]
#
# source://toys//lib/toys/standard_cli.rb#25
Toys::StandardCLI::CONFIG_DIR_NAME = T.let(T.unsafe(nil), String)

# Standard toys configuration file name.
#
# @return [String]
#
# source://toys//lib/toys/standard_cli.rb#31
Toys::StandardCLI::CONFIG_FILE_NAME = T.let(T.unsafe(nil), String)

# Standard data directory name in a toys configuration.
#
# @return [String]
#
# source://toys//lib/toys/standard_cli.rb#55
Toys::StandardCLI::DATA_DIR_NAME = T.let(T.unsafe(nil), String)

# Short description for the standard root tool.
#
# @return [String]
#
# source://toys//lib/toys/standard_cli.rb#79
Toys::StandardCLI::DEFAULT_ROOT_DESC = T.let(T.unsafe(nil), String)

# Help text for the standard root tool.
#
# @return [String]
#
# source://toys//lib/toys/standard_cli.rb#85
Toys::StandardCLI::DEFAULT_ROOT_LONG_DESC = T.let(T.unsafe(nil), String)

# Short description for the version flag.
#
# @return [String]
#
# source://toys//lib/toys/standard_cli.rb#96
Toys::StandardCLI::DEFAULT_VERSION_FLAG_DESC = T.let(T.unsafe(nil), String)

# Name of the standard toys executable.
#
# @return [String]
#
# source://toys//lib/toys/standard_cli.rb#67
Toys::StandardCLI::EXECUTABLE_NAME = T.let(T.unsafe(nil), String)

# Delimiter characters recognized.
#
# @return [String]
#
# source://toys//lib/toys/standard_cli.rb#73
Toys::StandardCLI::EXTRA_DELIMITERS = T.let(T.unsafe(nil), String)

# Standard index file name in a toys configuration.
#
# @return [String]
#
# source://toys//lib/toys/standard_cli.rb#37
Toys::StandardCLI::INDEX_FILE_NAME = T.let(T.unsafe(nil), String)

# Standard lib directory name in a toys configuration.
#
# @return [String]
#
# source://toys//lib/toys/standard_cli.rb#61
Toys::StandardCLI::LIB_DIR_NAME = T.let(T.unsafe(nil), String)

# Standard preload directory name in a toys configuration.
#
# @return [String]
#
# source://toys//lib/toys/standard_cli.rb#43
Toys::StandardCLI::PRELOAD_DIR_NAME = T.let(T.unsafe(nil), String)

# Standard preload file name in a toys configuration.
#
# @return [String]
#
# source://toys//lib/toys/standard_cli.rb#49
Toys::StandardCLI::PRELOAD_FILE_NAME = T.let(T.unsafe(nil), String)

# Name of the toys path environment variable.
#
# @return [String]
#
# source://toys//lib/toys/standard_cli.rb#102
Toys::StandardCLI::TOYS_PATH_ENV = T.let(T.unsafe(nil), String)

# Namespace for standard template classes.
#
# These templates are provided by Toys and can be expanded by name by passing
# a symbol to {Toys::DSL::Tool#expand}.
#
# source://toys//lib/toys.rb#72
module Toys::Templates; end

# Current version of the Toys command line executable.
#
# @return [String]
#
# source://toys//lib/toys/version.rb#8
Toys::VERSION = T.let(T.unsafe(nil), String)
