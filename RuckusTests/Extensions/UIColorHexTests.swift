import Testing
import UIKit

@testable import Ruckus

private struct RGBA {
  let red: CGFloat
  let green: CGFloat
  let blue: CGFloat
  let alpha: CGFloat

  init(color: UIColor) {
    var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
    color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    self.red = red
    self.green = green
    self.blue = blue
    self.alpha = alpha
  }
}

@Suite
struct UIColorHexTests {

  @Test
  func pureRed() {
    let result = RGBA(color: UIColor(hex: 0xFF0000))
    #expect(result.red == 1.0)
    #expect(result.green == 0.0)
    #expect(result.blue == 0.0)
    #expect(result.alpha == 1.0)
  }

  @Test
  func pureGreen() {
    let result = RGBA(color: UIColor(hex: 0x00FF00))
    #expect(result.red == 0.0)
    #expect(result.green == 1.0)
    #expect(result.blue == 0.0)
  }

  @Test
  func pureBlue() {
    let result = RGBA(color: UIColor(hex: 0x0000FF))
    #expect(result.red == 0.0)
    #expect(result.green == 0.0)
    #expect(result.blue == 1.0)
  }

  @Test
  func black() {
    let result = RGBA(color: UIColor(hex: 0x000000))
    #expect(result.red == 0.0)
    #expect(result.green == 0.0)
    #expect(result.blue == 0.0)
  }

  @Test
  func white() {
    let result = RGBA(color: UIColor(hex: 0xFFFFFF))
    #expect(result.red == 1.0)
    #expect(result.green == 1.0)
    #expect(result.blue == 1.0)
  }

  @Test
  func customAlpha() {
    let result = RGBA(color: UIColor(hex: 0xFF0000, alpha: 0.5))
    #expect(result.alpha == 0.5)
    #expect(result.red == 1.0)
  }

  @Test
  func defaultAlphaIsOne() {
    let result = RGBA(color: UIColor(hex: 0x123456))
    #expect(result.alpha == 1.0)
  }

  @Test
  func draculaBackgroundColor() {
    let result = RGBA(color: UIColor(hex: 0x282A36))
    let expectedRed = CGFloat(0x28) / 255
    let expectedGreen = CGFloat(0x2A) / 255
    let expectedBlue = CGFloat(0x36) / 255
    #expect(abs(result.red - expectedRed) < 0.001)
    #expect(abs(result.green - expectedGreen) < 0.001)
    #expect(abs(result.blue - expectedBlue) < 0.001)
  }
}
