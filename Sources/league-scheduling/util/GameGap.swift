
enum GameGap: Sendable {
    case no
    case always(Int)
    case upTo(Int)
    case minimumOf(Int)

    typealias TupleValue = (min: Int, max: Int)

    init?(htmlInputValue: some StringProtocol) {
        let values = htmlInputValue.lowercased().split(separator: " ")
        switch values.first {
        case "no":
            self = .no
        case "always":
            guard let number:Int = values[uncheckedPositive: 1]?.int() else { return nil }
            self = .always(number)
        case "up-to", "upto":
            guard let number:Int = values[uncheckedPositive: 1]?.int() else { return nil }
            self = .upTo(number)
        case "minimum", "minimum-of", "minimumof":
            guard let number:Int = values[uncheckedPositive: 1]?.int() ?? values[uncheckedPositive: 2]?.int() else { return nil }
            self = .minimumOf(number)
        default:
            return nil
        }
    }

    var minMax: TupleValue {
        switch self {
        case .no: (1, 1)
        case .always(let v): (v+1, v+1)
        case .upTo(let v): (1, v+1)
        case .minimumOf(let v): (v+1, 10)
        }
    }
}

// MARK: Codable
extension GameGap: Codable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        let string:String
        switch self {
        case .no: string = "no"
        case .always(let v): string = "always \(v)"
        case .upTo(let v): string = "upto \(v)"
        case .minimumOf(let v): string = "minimumof \(v)"
        }
        try container.encode(string)
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        if let value = Self(htmlInputValue: string) {
            self = value
        } else {
            self = .no
        }
    }
}