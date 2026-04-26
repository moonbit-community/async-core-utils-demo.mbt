///|
fn main {
  let uv = @uv.Loop::new() catch {
    e => {
      println("Error initializing uv: \{e}")
      return
    }
  }
  try {
    cat(uv, @uv.args()[1:])
    uv.close()
  } catch {
    e => {
      println("Error running cat: \{e}")
      uv.close() catch {
        _ => ()
      }
    }
  }
}

///|
fn cat(uv : @uv.Loop, files : ArrayView[Bytes]) -> Unit raise {
  if files is [] {
    copy_file(uv, @uv.stdin())
  } else {
    for file in files {
      if file is b"-" {
        copy_file(uv, @uv.stdin())
      } else {
        let input = uv.fs_open_sync(file, @uv.OpenFlags::read_only(), 0o644)
        copy_file(uv, input)
        uv.fs_close_sync(input)
      }
    }
  }
}

///|
fn copy_file(uv : @uv.Loop, input : @uv.File) -> Unit raise {
  let output = @uv.stdout()
  let buffer = Bytes::make(8192, 0)
  while true {
    let count = uv.fs_read_sync(input, [buffer[:]])
    if count == 0 {
      break
    }
    uv.fs_write_sync(output, [buffer[:count]])
  }
}
