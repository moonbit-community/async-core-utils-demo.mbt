///|
fn main {
  let uv = @uv.Loop::new() catch {
    e => {
      println("Error initializing uv: \{e}")
      return
    }
  }
  try {
    let args = @uv.args()
    let path = if args.length() > 1 {
      args[1]
    } else {
      @uv.cwd()
    }
    ls(uv, path)
    uv.close()
  } catch {
    e => {
      println("Error running ls: \{e}")
      try uv.close() catch {
        _ => ()
      }
    }
  }
}

///|
fn ls(uv : @uv.Loop, path : Bytes) -> Unit raise {
  let output = @uv.stdout()
  let newline : Bytes = b"\n"
  let scandir = uv.fs_scandir_sync(path, 0)
  let mut done = false
  while !done {
    try {
      let entry = scandir.next()
      uv.fs_write_sync(output, [entry.name()[:], newline[:]])
    } catch {
      @uv.Errno::EOF => done = true
      e => raise e
    }
  }
}
