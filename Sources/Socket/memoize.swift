infix operator ??=: AssignmentPrecedence

func ??= <T> (lhs: inout T?, rhs: @autoclosure () -> T) -> T {
  if lhs == nil {
    lhs = rhs()
  }
  return lhs!
}
