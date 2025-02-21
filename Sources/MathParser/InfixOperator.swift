// Copyright © 2021 Brad Howes. All rights reserved.

import Parsing

/**
 Parser for left-associative infix operations. Takes a parser for operators to recognize and a parser for values to use
 with the operator which could include operations that are of higher precedence than those parsed by the first parser.

 NOTE: this parser will succeed if it can parse at least one operand value. This can be problematic if you want to
 have an alternative case for a failed binary expression.

 Based on InfixOperator found in the Arithmetic perf test of https://github.com/pointfreeco/swift-parsing
 If you want support for right-associative operators, check there for a more robust implementation that does both kinds.
 */
struct LeftAssociativeInfixOperation<Input, Operator: Parser, Operand: Parser>: Parser
where Operator.Input == Input,
      Operand.Input == Input,
      Operator.Output == (Operand.Output, Operand.Output) -> Operand.Output
{
  private let `operator`: Operator
  private let operand: Operand
  private var implied: Operator.Output?

  /**
   Construct new parser

   - parameter operator: the parser that recognizes valid operators at a certain precedence level
   - parameter operand: the parser for values to provide to the operator that may include operations at a higher
   precedence level
   - parameter implied: an `Operator.Output` value to use when there is no operator to be found in the parse. This is
   only used to inject a multiplication operation between to operands when configured to do so.
   */
  @inlinable
  init(_ operator: Operator, higher operand: Operand, implied: Operator.Output? = nil) {
    self.operator = `operator`
    self.operand = operand
    self.implied = implied
  }
}

extension LeftAssociativeInfixOperation {

  /**
   Implementation of Parser method. Looks for "operand operator operand" sequences. There is a special case when
   `self.implied` is not nil: if two operands follow one another, then the operator from `self.implied` will be used
   for the "missing" operator.

   - parameter input: the input stream to parse
   - returns: the next output value found in the stream
   */
  @inlinable
  func parse(_ input: inout Input) rethrows -> Operand.Output {
    var lhs = try self.operand.parse(&input)
    var rest = input
    while true {
      if let operation = (try? self.operator.parse(&input)) ?? self.implied {
        do {
          let rhs = try self.operand.parse(&input)
          rest = input
          lhs = operation(lhs, rhs)
          continue
        } catch {
        }
      }
      // Reset and end parse
      input = rest
      return lhs
    }
  }
}
