## Utilities ##

Before delving into the code, here are a few low-level generic utilities which
are used all over it. These arguably belong in a separate library.

### Overall module ###

Executable scripts (tests, command-line applications) starts with a `require
'codnar'` line to access to the full Codnar code. This also serves as a
convenient list of all of Codnar's parts and dependencies:

[[lib/codnar.rb|named_chunk_with_containers]]

### Base test case ###

This class is used as the base class of all test cases; it allows creating
temporary files.

[[test/lib/test_case.rb|named_chunk_with_containers]]

### Collecting and testing for errors ###

Since Codnar needs to process multiple input files (in general, all the source
and most documentation files of a complex system), it is important that errors
will be reported with appropriate location information, and that processing
will continue so the full set of errors will be reported. This also makes the
code easier to test, using a special test case base class supporting error
collection:

[[test/lib/with_errors.rb|named_chunk_with_containers]]

Here is a simple test that demonstrates error collection:

[[test/collect_errors.rb|named_chunk_with_containers]]

And here is the implementation:

[[lib/codnar/errors.rb|named_chunk_with_containers]]

### Tests with a fake file system ###

Since Codnar manipulates files (source files, chunk files, generated HTML
files), it is very useful to be able to execute file-related tests with a fake
file system. This is a more elegant alternative to creating and cleaning a
temporary physical directory for the test. For simplicity we assume all(most)
such tests also collect errors.

[[test/lib/with_fakefs.rb|named_chunk_with_containers]]

### Extending the Hash class ###

We extend the builtin Hash class in three ways. Two will be described further
below; a third is to make all Hash objects behave as OpenStruct, that is, allow
accessing and setting values using "." notation. This allows us to avoid
defining classes for "dumb" data structures, while allowing them to be dumped
and loaded from clean YAML files. Here is a simple test of accessing missing
keys:

[[test/missing_keys.rb|named_chunk_with_containers]]

And here is the implementation:

[[lib/codnar/core_ext/hash.rb|named_chunk_with_containers]]

### Extending the String class ###

We extend the builtin String class to manage indentation and convert chunk
names to identifiers. These functions will be decribed below when used in the
code.

[[lib/codnar/core_ext/string.rb|named_chunk_with_containers]]

In addition, we also provide a method for cleaning up messy HTML code generated
by markup formatters:

[[Clean markup HTML|named_chunk_with_containers]]

## Splitting files into chunks ##

Codnar makes the reasonable assumption that each source file can be effectively
processed as a sequence of lines. This works well in practice for all "text"
source files. It fails miserably for "binary" source files, but such files
don't work that well in most generic source management tools (such as version
management systems).

A second, less obvious assumption is that it is possible to classify the source
file lines to "kinds" using a simple state machine. The classified lines are
then grouped into nested chunks based on the two special line kinds
`begin_chunk` and `end_chunk`. The other line kinds are used to control how the
lines are formatted into HTML.

The collected chunks, with the formatted HTML for each one, are then stored in
a chunks file to be used later for weaving the overall HTML narrative.

### Scanning Lines ###

Scanning a file into classified lines is done by the `Scanner` class.
Here is a simple test that demonstrates using the scanner:

[[test/scan_lines.rb|named_chunk_with_containers]]

And here is the implementation:

[[lib/codnar/scanner.rb|named_chunk_with_containers]]

As we can see, the implementation is split into two main parts. First, all
shorthands in the syntax definition are expanded (possibly generating errors).
Then, the expanded syntax is applied to a file, to generate a sequence of
classified lines.

#### Scanner Syntax Shorthands ####

The syntax is expected to be written by hand in a YAML file. We therefore
provide some convenient shorthands (listed above) to make YAML syntax files
more readable. These shorthands must be expanded to their full form before we
can apply the syntax to a file. There are two sets of shorthands we need to
expand:

* [[Scanner pattern shorthands|named_chunk_with_containers]]

* [[Scanner state shorthands|named_chunk_with_containers]]

The above code modifies the syntax object in place. This is safe because we are
working on a `deep_clone` of the original syntax:

[[Deep clone|named_chunk_with_containers]]

#### Classifying Source Lines ####

Scanning a file to classified lines is a simple matter of applying the current
state transitions to each line:

[[Scanner file processing|named_chunk_with_containers]]

If a line matches a state transition, it is classified accordingly. Otherwise,
it is reported as an error:

[[Scanner line processing|named_chunk_with_containers]]

### Merging scanned lines to chunks ###

Once we have the array of scanned classified lines, we need to merge them into
nested chunks. Here is a simple test that demonstrates using the merger:

[[test/merge_lines.rb|named_chunk_with_containers]]

And here is the implementation:

[[lib/codnar/merger.rb|named_chunk_with_containers]]

#### Merging nested chunk lines ####

To merge the nested chunk lines, we maintain a stack of the current chunks.
Each `begin_chunk` line pushes another chunk on the stack, and each `end_chunk`
line pops it. If any chunks are not properly terminated, they will remain in
the stack when all the lines are processed.

[[Merging nested chunk lines|named_chunk_with_containers]]

#### Unindenting merged chunk lines ####

Nested chunks are typically indented relative to their container chunks.
However, in the generated documentation, these chunks are displayed on their
own, and preserving this relative indentation would reduce their readability.
We therefore unindent all chunks as much as possible as the final step.

[[Unindenting chunk lines|named_chunk_with_containers]]

The `unindent` method is an extension to the String class. Here is a simple
test that demonstrates unindenting text:

[[test/unindent_text.rb|named_chunk_with_containers]]

And here is the implementation:

[[Unindent text|named_chunk_with_containers]]

### Generating chunk HTML ###

Now that we have each chunk's lines, we need to convert them to HTML.

#### Grouping lines of the same kind ####

Instead of formatting each line on its own, we batch the operations to work on
all lines of the same kind at once. Here is a simple test that demonstrates
using the grouper:

[[test/group_lines.rb|named_chunk_with_containers]]

And here is the implementation:

[[lib/codnar/grouper.rb|named_chunk_with_containers]]

#### Formatting lines as HTML ####

Formatting is based on a configuration that specifies, for (a group of) lines
of each kind, how to convert it to HTML. Here is a simple test that
demonstrates using the formatter:

[[test/format_lines.rb|named_chunk_with_containers]]

And here is the implementation:

[[lib/codnar/formatter.rb|named_chunk_with_containers]]

#### Basic formatters ####

The implementation contains some basic formatting functions. These are
sufficient for generic source code processing.

[[Basic formatters|named_chunk_with_containers]]

#### Markup formats ####

The `markup_lines_to_html` formatter above relies on the existence of a class
for converting comments from the specific markup format to HTML. Currently, two
such formats are supported:

* RDoc, the default markup format used in Ruby comments. Here is a simple test
  that demonstrates using RDoc:

  [[test/expand_rdoc.rb|named_chunk_with_containers]]

  And here is the implementation:

  [[lib/codnar/core_ext/rdoc.rb|named_chunk_with_containers]]

* Markdown, a generic markup syntax used across many systems and languages.
  Here is a simple test that demonstrates using Markdown:

  [[test/expand_markdown.rb|named_chunk_with_containers]]

  And here is the implementation:

  [[lib/codnar/core_ext/markdown.rb|named_chunk_with_containers]]

#### Syntax highlighting using GVIM ####

If you have `gvim` istalled, it is possible to use it to generate syntax
highlighting. This is a *slow* operation, as `gvim` was never meant to be used
as a command-line tool. However, what it lacks in speed it compensates for in
scope; almost any language you can think of has a `gvim` syntax highlighting
definition. Here is a simple test that demonstrates using `gvim` for syntax
highlighting:

[[test/highlight_syntax.rb|named_chunk_with_containers]]

And here is the implementation:

[[lib/codnar/gvim.rb|named_chunk_with_containers]]

### Putting it all together ###

Now that we have all the separate pieces of functionality for splitting source
files into HTML chunks, we need to combine them to a single convenient service.

#### Splitting code files ####

Here is a simple test that demonstrates using the splitter for source code
files:

[[test/split_code.rb|named_chunk_with_containers]]

And here is the implementation:

[[lib/codnar/splitter.rb|named_chunk_with_containers]]

#### Splitting documentation files ####

The narrative documentation is expected to reside in one or more files, which
are also "split" to a single chunk each. Having both documentation and code
exist as chunks allows for uniform treatment of both when weaving, as well as
allowing for pre-processing the documentation files, if necessary. For example,
Codnar currently supports for documentation the same two markup formats that
are also supported for code comments. Here is a simple test that demonstrates
"splitting" documentation (using the same implementation as above):

[[test/split_documentation.rb|named_chunk_with_containers]]

### Built-in configurations ###

The splitting mechanism defined above is pretty generic. To apply it to a
specific system requires providing the appropriate configuration. The system
provides a few specific built-in configurations which may be useful "out of the
box". Currently, these built-in configurations are focused on documenting Ruby
code and GVim.

If one is willing to give up altogether on syntax highlighting and comment
formatting, the system would be applicable as-is to any programming language.
Properly highlighting almost any known programming language syntax would be a
simple matter of passing the correct syntax parameter to GVIM.

Properly formatting comments in additional mark-up formats would be trickier.
First, a proper pattern needs to be established for extracting the comments
(`/*`, `//`, `--`, etc.). Them, the results need to be converted to HTML. One
way would be to pass them through GVim syntax highlighting with an appropriate
format (e.g, `syntax=doxygen`). Another would be to invoke some Ruby library;
finally, one could invoke some external tool to do the job. The latter two
options would require providing additional glue Ruby code, similar to the GVim
class above.

At any rate, here are the built-in configurations:

[[lib/codnar/configuration.rb|named_chunk_with_containers]]

(Built-in weaving templates are described later.)

#### Documentation "Splitting" ####

These are pretty simple configurations, applicable to files containing a piece
of the narrative in some supported format.

[[Built-in documentation "splitting" configurations|named_chunk_with_containers]]

#### Chunk Splitting ####

There are many ways to denote code regions (and, therefore, chunks). The
following covers GVim's default scheme; there is also VisualStudio `#region`
notation, as well as many others.

[[Built-in chunk splitting configurations|named_chunk_with_containers]]

#### Comment splitting ####

The following only covers shell-like `#`  comments, and a few markup formats.
There are too many other alternatives to list here.

[[Built-in comment splitting configurations|named_chunk_with_containers]]

#### Syntax highlighting ####

Supporting a specific programming language (other than dealing with comments)
is very easy using GVim for syntax highlighting, as demonstrated here:

[[Built-in syntax highlighting configurations|named_chunk_with_containers]]

#### Combining configurations ####

The above configurations can be used in combination with each other, as
demonstrated by the following tests:

[[test/split-configurations.rb|named_chunk_with_containers]]

Combining configurations rquires deep-merging. This allows complex nested
structures to be merged. There is even a way for arrays to append elements
before/after the array they are merged with. Here is a simple test that
demonstrates deep-merging complex structures:

[[test/deep_merge.rb|named_chunk_with_containers]]

And here is the implementation:

[[Deep merge|named_chunk_with_containers]]

## Storing chunks on the disk ##

### Writing chunks to disk ###

In any realistic system, the number of source files and chunks will be such
that it makes sense to store the chunks on the disk for further processing.
This allows incorporating the split operation as part of a build tool chain,
and only re-splitting modified files. Here is a simple test demonstrating
writing chunks to the disk:

[[test/write_chunks.rb|named_chunk_with_containers]]

And here is the implementation:

[[lib/codnar/writer.rb|named_chunk_with_containers]]

### Reading chunks to memory ###

Having written the chunks to the disk requires us, at some following point in
time, to read them back into memort. This is the first time we will have a view
of the whole documented system, which allows us to detect several classes of
consistency errors: Some chunks may be left out of the final narrative
(consider this the equivalent of tests code coverage); we may be referring to
missing (or misspelled) chunk names; and, finally, we need to deal with
duplicate chunks.

In literate programming, it is trivial to write a chunk once and use it in
several places in the compiled source code. The classical example is C/C++
function signatures that need to appear in both the `.h` and `.c`/`.cpp` files.
However, in some cases this practice makes sense for other pieces of code, and
since the ultimate source code contains only one copy of the chunk, this does
not suffer from the typical copy-and-paste issues.

In inverse literate programming, if the same code appears twice (as a result of
copy-and-paste), then it does suffer from the typical copy-and-paste issues.
The most serious of these is, of course, that when only one copy is changed.
The way that Codnar helps alleviate this problem is that if the same chunk
appears more than once in the source code, its content is expected to be
exactly the same in both cases (up to indentation). This should not be viewed
as endorsement of copy-and-paste programming; Using duplicate chunks should be
a last resort measure to combat restrictions in the programming language and
compilation tool chain.

#### Chunk identifiers ####

The above definition raises the obvious question: what does "the same chunk"
mean? As far as Codnar is concerned, a chunk is uniquely identified by its
name, which is specified on the `begin_chunk` line. The unique identifier is
not the literal name but a transformation of it. This allows us to ignore
capitalization, white space, and any punctuation that may appear in the name.
It also allows us to use the resulting ID as an HTML anchor name, without
worrying about HTML's restictions on such names.

Here is a simple test demonstrating converting names to identifiers:

[[test/identify_chunks.rb|named_chunk_with_containers]]

And here is the implementation:

[[Convert names to identifiers|named_chunk_with_containers]]

#### In-memory chunks storage ####

Detecting unused and/or duplicate chunks requires us to have in-memory chunk
storage that tracks all chunks access. Here is a simple test demonstrating
reading chunks into the storage and handling the various error conditions
listed above:

[[test/read_chunks.rb|named_chunk_with_containers]]

And here is the implementation:

[[lib/codnar/reader.rb|named_chunk_with_containers]]

## Weaving chunks into HTML ##

Assembling the final HTML requires combining both the narrative documentation
and source code chunks. This is done top-down starting at a "root"
documentation chunk and recursively embedding nested documentation and code
chunks into it.

### Weaving chunks together ###

When embedding a documentation chunk inside another documentation chunk, things
are pretty easy - we just need to insert the embedded chunk HTML into the
containing chunk. When embedding a source code chunk into the documentation,
however, we may want to wrap it in some boilerplate HTML, providing a header,
footer, borders, links, etc. Therefore, the HTML-sh syntax we use to embed a
chunk into the documentation is `<embed src="..."
type="x-codnar/template-name"/>`.

The templates are normal ERB templates. As a special and highly magical case,
the template named `file` simply embeds the specified file into the
documentation at that point. This is similar to the "server side include"
available in many web framework, or to a client-side `iframe` directive. This
really should have been part of HTML; why HTML allows unrestricted inclusion of
JavaScript code but denies the same ability to HTML and CSS code is beyond me.

At any rate, here is a simple test demonstrating applying different templates
to the embedded code chunks:

[[test/weave_configurations.rb|named_chunk_with_containers]]

Here is the implementation:

[[lib/codnar/weaver.rb|named_chunk_with_containers]]

And here are the pre-defined weaving template configurations:

[[Built-in weaving templates|named_chunk_with_containers]]

## Invoking the functionality ##

There are two ways to invoke Codnar's functionality - from the command line,
and (for Ruby projects) as integrated Rake tasks.

### Command Line Applications ###

The base command line Application class handles execution from the command
line, with the usual standard options, as well as some Codnar-specific ones:
the ability to specify configuration files and/or built-in configurations, and
the ability to include additional extension code. Together, these allow
configuring and extending Codnar's behavior to cover the specific system's
needs.

In addition, the Application class also supports invocation from unit tests.
Here is a simple test demonstrating this mode of invocation:

[[test/run_application.rb|named_chunk_with_containers]]

And here is the implementation:

[[lib/codnar/application.rb|named_chunk_with_containers]]

To invoke an application in tests in a controlled way, we need to preserve the
state of certain global variables around the invocation:

[[lib/codnar/globals.rb|named_chunk_with_containers]]

#### Application for splitting files ####

Here is a simple test demonstrating invoking the command-line application for
splitting files:

[[test/run_split.rb|named_chunk_with_containers]]

Here is the implementation:

[[lib/codnar/split.rb|named_chunk_with_containers]]

And here is the actual command-line application script:

[[bin/codnar-split|named_chunk_with_containers]]

#### Application for weaving chunks ####

Here is a simple test demonstrating invoking the command-line application for
weaving chunk to HTML:

[[test/run_weave.rb|named_chunk_with_containers]]

Here is the implementation:

[[lib/codnar/weave.rb|named_chunk_with_containers]]

And here is the actual command-line application script:

[[bin/codnar-weave|named_chunk_with_containers]]

### Rake Integration ###

For Ruby projects (or any other project using Rake), it is also possible to
invoke Codnar using Rake tasks. Here is a simple test demonstrating using the
Rake tasks:

[[test/rake_tasks.rb|named_chunk_with_containers]]

To use these tasks in a Rakefile, one needs to `require 'codnar/rake'`. The
code implements a singleton that holds the global state shared between tasks:

[[lib/codnar/rake.rb|named_chunk_with_containers]]

#### Task for splitting files ####

To split one or more files to chunks, create a new SplitTask. Multiple such
tasks may be created; this is required if different files need to be split
using different configurations.

[[lib/codnar/rake/split_task.rb|named_chunk_with_containers]]

#### Task for weaving chunks ####

To weave the chunks together, create a single WeaveTask.

[[lib/codnar/rake/weave_task.rb|named_chunk_with_containers]]

## Building the Codnar gem ##

The following Rakefile is in charge of building the gem, with the help of some
tools described below.

[[Rakefile|named_chunk_with_containers]]

### Automatic gem version number ###

The gem version number is taken from the following tool, with combination with
a running version number extracted from `git`:

[[tools/codnar-version|named_chunk_with_containers]]

And here is the current generated version file:

[[lib/codnar/version.rb|named_chunk_with_containers]]

### Automatic change log ###

A standard format change log file is maintained by the following tool:

[[tools/codnar-changelog|named_chunk_with_containers]]

### Automated commit procedure ###

The above two tools and the build process in general assumes that every commit
to `git` (on the main branch, anyway) is done by the following automated
procedure:

[[tools/codnar-commit|named_chunk_with_containers]]

## Formatting generated HTML ##

The generated HTML requires some tweaking to yield aesthetic, readable results.
This tweaking consists of using Javascript to generate a table of content, and
using CSS to make the HTML look better.

### Javascript table of content ###

The following code is not very efficient or elegant but it does a basic job of
iunjecting a table of content into the generated HTML.

[[doc/contents.js|named_chunk_with_containers]]

### CSS files ###

To avoid dealing with the different default styles used by different browsers,
we employ the YUI CSS [reset](http://developer.yahoo.com/yui/reset/) file:

[[doc/reset.css|named_chunk_with_containers]]

This requires us to restore the default look and feel of the standard HTML
elements, using the YUI [base](http://developer.yahoo.com/yui/base/) CSS style
file. Resetting and restoring the default CSS styles is inelegant, but it is
the only current way to get a consistent presentation of HTML.

[[doc/base.css|named_chunk_with_containers]]

Finally, we can apply styles specific to our HTML. Some of these override the
default styles established by the base CSS file above. We do this instead of
directly tweaking the base CSS file, to allow easy upgrade to new versions
if/when YUI release any.

[[doc/style.css|named_chunk_with_containers]]