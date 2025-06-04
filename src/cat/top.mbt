///|
fn main {
  try @async.start(fn() { cat(@env.args()[1:]) }) catch {
    e => println("Error running cat: \{e}")
  }
}

///|
async fn cat(files : ArrayView[String]) -> Unit! {
  if files is [] {
    // read from stdin only once
    let input = @async.stdin.read_text(encoding=UTF8)
    @async.stdout.write_text(input, encoding=UTF8)
  } else {
    for file in files {
      try {
        if file is "-" {
          // read from stdin
          let input = @async.stdin.read_text(encoding=UTF8)
          @async.stdout.write_text(input, encoding=UTF8)
          continue
        } else {
          let content = @async.path(file).read_text(encoding=UTF8)
          @async.stdout.write_text(content, encoding=UTF8)
        }
      } catch {
        e =>
          @async.stderr.write_text(
            "Error reading file \{file}: \{e}",
            encoding=UTF8,
          )
      }
    }
  }
}
