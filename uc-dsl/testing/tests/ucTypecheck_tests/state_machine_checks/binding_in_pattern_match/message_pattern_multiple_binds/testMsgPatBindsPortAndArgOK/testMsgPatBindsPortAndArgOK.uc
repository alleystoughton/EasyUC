direct A' {
in x@bla(p:port)
}

direct A {A:A'}

functionality F implements A {

 party P serves A.A {

  initial state Is 
  {
   match message with
    sender@A.A.bla(p) => {fail.}
   end
  }

 }

}
