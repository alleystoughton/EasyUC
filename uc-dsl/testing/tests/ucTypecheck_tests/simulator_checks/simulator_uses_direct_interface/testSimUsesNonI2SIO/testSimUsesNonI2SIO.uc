direct D' {
in  x@bla()
out bli()@x
}

direct D {D:D'}

functionality R() implements D {

 party P serves D.D {

  initial state I {
  match message with * => {fail.} end
  }
 }
}

simulator S uses D simulates R() {

  initial state I {
  match message with D.D.* => {fail.} end
  }

}
