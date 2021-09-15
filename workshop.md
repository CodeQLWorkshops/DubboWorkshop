# CodeQL for Ruby Workshop

GitHub Day of Learning, 19th August 2021

Presented by @calumgrant

Slack: #codeql-support

Documentation & tools: https://codeql.github.com

Workshop format: This is a hands-on workshop where you will be using the CodeQL Visual Studio Extension to write CodeQL.

Please feel free to ask questions at any time. If we run out of time, this is not a problem. We will just stop at an appropriate point. You can complete the remaining material in your own time if you want to. You are encouraged to experiment as you go along. Hints and solutions are provided. Where you see an arrow like this you can click to expand it:

<details>
<summary>
Hints
</summary>
Here are some hints.
</details>


# Task 0: Setup

Follow the instructions in the [README](README.md) - you want to have [this repository](https://github.com/github/codeql-ruby-day-of-learning) open in Visual Studio Code. We recommend using Codespaces, but it is fine to use a local version of Visual Studio Code. Make sure that the extension and CodeQL CLI are the latest versions (1.5.2/2.5.9).

The databases are included in the snapshot in the [databases](databases/) folder. You can also create your own databases using the CodeQL CLI.

<details>
<summary>
How to create your own database (click to expand)
</summary>

Using the latest CodeQL CLI, you can simply use the built-in Ruby support to create databases. For the beta period, you do need to turn it on explicitly though, using the environment variable.

```bash
% export CODEQL_ENABLE_EXPERIMENTAL_FEATURES=true
% codeql database create ~/databases/jekyll -l ruby -s ~/projects/jekyll
```

</details>

If you already cloned the repo, `git pull` to get the latest changes.

# Task 1: Securing dangerous properties in Pages

For this exercise, we will be looking at improving the security of the GitHub pages repo, as described in https://github.com/github/pages/pull/3329. We will focus on GitHub Pages today simply because a recent security audit was performed on this repo (see https://github.com/github/pe-security-lab/issues/822). Hopefully this example will be relevant to some of you.

## Motivation

As an example, we want to find calls like

```rb
config.delete("collections_dir")
```

and replace them with

```rb
config["collections_dir"] = ""
```

The dangerous properties are: `forwarded_env`, `coderay`, and `collections_dir`.

Outline:

1. Create a new CodeQL file
2. Find all method calls
3. Limit it to delete calls
4. Exploration: Autocomplete, jump-to-definition, AST Viewer
4. Limit it to dangerous properties
5. Turn it into a query



Firstly, create a new query file in the root folder, and make sure that the "pages" database is selected.

## Exercise 1.1: Find all method calls using the `MethodCall` class

You should get 11400 results.

<details>
<summary>Hints</summary>

```
import ...

from ...
select ...
```

</details>


<details>
<summary>Solution</summary> 

```ql
import ruby

from MethodCall call
select call
```

</details>

## Exercise 1.2: Restrict the results to methods called `delete`.

You should get 52 results.

<details>
<summary>Hints</summary>

- Use `MethodCall.getMethodName()` to get the method name.

</details>

<details>
<summary>Solution</summary> 

```ql
import ruby

from MethodCall call
where call.getMethodName() = "delete"
select call
```

</details>

* Explore some of the results by clicking on them
* Explore autocomplete
* Explore pop-up help
* Jump to the QL class definition
* Use the AST viewer. Right-click on any Ruby code and select "CodeQL: View AST".
* Look at query history

## Exercise 1.3: Restrict the first argument to strings

The `and` keyword combines two logical expressions.

You should get 31 results.

<details>
<summary>Hints</summary>

- Ensure that the first argument has type `StringLiteral`
- You can use `MethodCall.getArgument(0)` to get the first argument.

</details>

<details>
<summary>Solution</summary> 

```ql
import ruby

from MethodCall call
where
    call.getMethodName() = "delete" and
    call.getArgument(0) instanceof StringLiteral
select call
```

</details>

## Exercise  1.4: Restrict the results to the relevant properties

This should give 6 results.

<details>
<summary>Hints</summary>

- You can use `StringLiteral.getValueText()` to get the value of the literal
- You can use the expression `["forwarded_env", "coderay", "collections_dir"]` to encode a multi-valued expression in CodeQL.

</details>

<details>
<summary>Solution</summary> 

```ql
import ruby

from MethodCall call, StringLiteral literal
where
    call.getMethodName() = "delete" and
    literal = call.getArgument(0) and
    literal.getValueText() = ["forwarded_env", "coderay", "collections_dir"]
select call
```

or

```ql
import ruby

from MethodCall call
where
    call.getMethodName() = "delete" and
    call.getArgument(0).(StringLiteral).getValueText() = 
        ["forwarded_env", "coderay", "collections_dir"]
select call
```

</details>

## Exercise 1.5: Remove false-positives

<details>
<summary>Hints</summary>

- Use the AST viewer to find the parent types
- Exclude parents whose type is `LogicalOrExpr`
- Use `getParent()` to get the parent of an expression

</details>

<details>
<summary>Solution</summary>

```ql
import ruby

from MethodCall call
where
    call.getMethodName() = "delete" and
    call.getArgument(0).(StringLiteral).getValueText() = 
        ["forwarded_env", "coderay", "collections_dir"] and
    not call.getParent() instanceof LogicalOrExpr
select call
```

You should have 4 results.

</details>

* Look at quick eval.

## Exercise 1.6: Turn it into a query. 

You can choose to run this query again on all pushes and PRs as a custom query. This prevents the developers from reintroducing the vulnerability in the future.

Create some metadata at the top of the query in the following format:

```
/**
 * @name ...
 * @description ...
 * @kind problem
 * @problem.severity warning
 * @precision low
 * @id ...
 */
```

Add a string to the `select`

```
select call, "..."
```

<details>
<summary>Solution</summary> 

```ql
/**
 * @name Deleting a dangerous property.
 * @description ...
 * @kind problem
 * @problem.severity warning
 * @precision low
 * @id rb/property-delete
 */

import ruby

from MethodCall call
where
    call.getMethodName() = "delete" and
    call.getArgument(0).(StringLiteral).getValueText() = 
        ["forwarded_env", "coderay", "collections_dir"] and
    not call.getParent() instanceof LogicalOrExpr
select call, "Deleting a dangerous property."
```

</details>

# Task 2: Remote code execution in Jekyll

Importing modules from user-controlled locations is a remote code execution vulnerability (especially if you can create the file to execute).

```ruby
      def try_require(type, name)
        require "kramdown/#{type}/#{Utils.snake_case(name)}"
      rescue LoadError
        false
      end
```

Switch databases to `databases/jekyll.zip`.

## Exercise 2.1: Find all `require` statements

There should be 146 results.

<details>
<summary>Hints</summary>

* This is very similar to finding calls to `delete`.
* Use `MethodCall` and `getMethodName()`

</details>

<details>
<summary>Solution</summary>

```ql
import ruby

from MethodCall call
where call.getMethodName() = "require"
select call
```

If you have 198 results, then you are still on the "pages" database!

</details>

## Exercise 2.2: Find those just with interpolated strings

Try to find the interesting result.

```ruby
require "kramdown/#{type}/#{Utils.snake_case(name)}"
```

<details>
<summary>Hints</summary>

- You need to find a `StringLiteral` with components
- Use `StringLiteral.getNumberOfComponents()`

</details>

<details>
<summary>Solution</summary>

```ql
import ruby

from MethodCall call
where
  call.getMethodName() = "require" and
  call.getArgument(0).(StringLiteral).getNumberOfComponents() > 1
select call, "Potential RCE."
```

</details>

# Next steps

* For tools and documentation, visit https://codeql.github.com
* Slack channel: #codeql-support
* Enable CodeQL analysis for your own repos
