import SpriteKit

enum UIConstants {
    enum Spacing {
        static let xsmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xlarge: CGFloat = 24
    }

    enum Radius {
        static let small: CGFloat = 6
        static let medium: CGFloat = 10
        static let large: CGFloat = 16
    }

    enum Text {
        static let titleFont = "AvenirNext-Heavy"
        static let boldFont = "AvenirNext-Bold"
        static let regularFont = "AvenirNext-Regular"
        static let mediumFont = "AvenirNext-Medium"
    }

    enum Z {
        static let background: CGFloat = -20
        static let decor: CGFloat = -10
        static let content: CGFloat = 0
        static let ui: CGFloat = 10
        static let title: CGFloat = 12
        static let topBar: CGFloat = 14
        static let modal: CGFloat = 100
    }
}


