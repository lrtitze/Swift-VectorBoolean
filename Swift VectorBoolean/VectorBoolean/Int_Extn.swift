
import Foundation

extension Int {

  /// Our utility extension to ease identification
  /// of places where we test for even numbers
  public var isEven: Bool {
    get {
      return self % 2 == 0
    }
  }

  /// Our utility extension to ease identification
  /// of places where we test for odd numbers
  public var isOdd: Bool {
    get {
      return self % 2 == 1
    }
  }

}