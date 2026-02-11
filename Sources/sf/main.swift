import Foundation

/// Logs `s` to the standard error.
private func error(_ s: String) {
  try! FileHandle.standardError.write(contentsOf: "error: \(s)\n".data(using: .utf8)!)
}

/// Logs `s` to the standard error and exits.
private func fail(_ s: String) -> Never {
  error(s)
  exit(EXIT_FAILURE)
}

/// Runs the command line tool with the given arguments.
private func run<T: Collection<String>>(_ arguments: T) {
  // Parse the arguments.
  var options: [String] = []
  var input: String? = nil

  for a in arguments {
    switch a {
    case "-h", "-p", "-t":
      options.append(a)

    default:
      if a.starts(with: "-") {
        fail("invalid option '\(a)'")
      } else if input != nil {
        fail("multiple inputs")
      } else {
        input = a
      }
    }
  }

  // Did the user ask for help?
  if options.contains("-h") {
    let help = """
      USAGE: sf [-h] [-p] [-t] input
      
      OPTIONS:
        -h Show help information.
        -p Show the result of parsing and exit.
        -t Show the result of typing and exit.
      """
    print(help)
    exit(EXIT_SUCCESS)
  }

  // Open the input file and read its contents.
  let f = input ?? fail("no input")
  let i = (try? String.init(contentsOfFile: f, encoding: .utf8)) ?? fail("cannot read input")

  // Run the pipeline.
  do {
    // Parsing
    let p = try Parser.parse(i)
    if options.contains("-p") {
      print(p)
      exit(EXIT_SUCCESS)
    }

    // Typing.
    let t = try p.type(in: .init())
    if options.contains("-t") {
      print("\(p) : \(t)")
      exit(EXIT_SUCCESS)
    }

    // Evaluation.
    print(try p.eval(in: .init()))
    exit(EXIT_SUCCESS)
  } catch let e {
    fail(String(describing: e))
  }
}

run(CommandLine.arguments[1...])
