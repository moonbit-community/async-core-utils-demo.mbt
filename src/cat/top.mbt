///|
fn main {
  @async.start(fn() { cat(@env.args()[1:]) }) catch {
    e => println("Error running cat: \{e}")
  }
}

///|
async fn cat(files : ArrayView[String]) -> Unit raise {
  if files is [] {
    @async.stdin.read_streaming() // read from stdin only once
  } else {
    for file in files {
      if file is "-" {
        @async.stdin.read_streaming() // read from stdin
        continue
      } else {
        @async.path(file).read_all()
      }
    }
  }
}

///|
async fn &@async.ToPath::read_all(input : Self) -> Unit raise {
  @async.stdout.write_text(input.read_text(encoding=UTF8), encoding=UTF8)
}

///|
async fn @string.View::to_stdout(self : Self) -> Unit raise {
  @async.stdout.write_text(self, encoding=UTF8)
}

///|
async fn @async.File::read_streaming(input : Self) -> Unit raise {
  let decoder = @encoding.decoder(UTF8)
  let string : Array[@string.View] = []
  let stream = input.read()
  stream.each(fn(bytes) {
    let str = decoder.decode(bytes, stream=true)
    if str.find("\n") is Some(index) {
      for s in string {
        s.to_stdout()
      }
      str.charcodes(end=index + 1).to_stdout()
      string.clear()
      string.push(str.charcodes(start=index + 1))
    }
  })
}
