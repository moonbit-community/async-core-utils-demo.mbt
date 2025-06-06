///|
priv struct Option {
  mut recurse : Bool
  mut level : UInt
} derive(Show)

///|
impl @clap.Value for Option with add_value(self, name, value, positional) {
  if name is "level" && not(positional) {
    try {
      self.level = @strconv.parse_uint(value)
    } catch {
      e =>
        raise @clap.InvalidArgumentValue(
          "\"--level\" should be an integer. Got \{e}",
        )
    }
  }
}

///|
impl @clap.Value for Option with set_flag(self, name, value) {
  if name is "recurse" {
    self.recurse = value
  }
}

///|
fn main {
  try
    @async.start(fn() {
      let opt = { recurse: false, level: 1 }
      let parser = @clap.Parser::new(prog="ls", args={
        "recurse": @clap.Arg::flag(short='R', help="recurse into directories"),
        "level": @clap.Arg::named(
          short='L',
          help="limit the depth of recursion",
          nargs=@clap.Nargs::AtMost(1),
        ),
      })
      let help = try parser.parse(opt, @env.args()[1:]) catch {
        InvalidArgumentValue(e) => {
          @async.stderr.write_text("Error: \{e}\n", encoding=UTF8)
          return
        }
        e => {
          @async.stderr.write_text("Error: \{e}\n", encoding=UTF8)
          return
        }
      }
      if help is Some(help) {
        @async.stdout.write_text(help, encoding=UTF8)
        return
      }
      let dir = ls(
        path?=@env.current_dir(),
        depth=if opt.recurse { opt.level } else { 1 },
      )
      dir.show()
    }) catch {
    e => println("Error running cat: \{e}")
  }
}

///|
enum File {
  File(&@async.ToPath)
  Directory(&@async.ToPath, Array[File])
}

///|
async fn ls(path? : String, depth~ : UInt = 1) -> File! {
  let file = if path is Some(path) {
    File::from_path(path, depth~)
  } else {
    File::from_path(@async.cwd(), depth~)
  }
  file
}

///|
async fn File::from_path(path : &@async.ToPath, depth~ : UInt = 1) -> File! {
  if path.is_dir() {
    let entries = []
    if depth > 0 {
      path
      .iter()
      .each(fn(entry) { entries.push(File::from_path(entry, depth=depth - 1)) })
    }
    Directory(path, entries)
  } else {
    File(path)
  }
}

///|
async fn File::show(self : File) -> Unit! {
  match self {
    File(path) => @async.stdout.write_text("\{path.name()}\n", encoding=UTF8)
    Directory(root, entries) => {
      let chalk = @chalk.chalk().color(Blue)
      let queue = @queue.new()
      for entry in entries {
        if entry is Directory(path, _) {
          @async.stdout.write_text(
            chalk.render("\{path.name()} "),
            encoding=UTF8,
          )
          queue.push(entry)
        } else if entry is File(path) {
          @async.stdout.write_text("\{path.name()} ", encoding=UTF8)
        }
      }
      @async.stdout.write_text("\n\n", encoding=UTF8)
      while queue.pop() is Some(f) {
        if f is File(path) {
          @async.stdout.write_text(path.name(), encoding=UTF8)
        } else if f is Directory(p, entries) {
          @async.stdout.write_text("./\{p.relative_to(root)}:\n", encoding=UTF8)
          for entry in entries {
            if entry is Directory(path, _) {
              @async.stdout.write_text(
                chalk.render("\{path.name()} "),
                encoding=UTF8,
              )
              queue.push(entry)
            } else if entry is File(path) {
              @async.stdout.write_text("\{path.name()} ", encoding=UTF8)
            }
          }
        }
        @async.stdout.write_text("\n\n", encoding=UTF8)
      }
    }
  }
}
