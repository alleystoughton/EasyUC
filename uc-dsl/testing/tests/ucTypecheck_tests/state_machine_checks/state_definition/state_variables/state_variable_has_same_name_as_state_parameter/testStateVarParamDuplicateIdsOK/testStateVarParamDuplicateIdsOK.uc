direct A' {
in x@bla()
}

direct A {A:A'}

functionality F() implements A {
 party P serves A.A {
  initial state S
  {
   match message with
    * => {fail.}
   end
  }

  state T(p:port)
  {
   var q:port;
   match message with
    * => {fail.}
   end
  }

 }
}

