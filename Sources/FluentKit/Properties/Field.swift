extension Model {
    public typealias Field<Value> = ModelField<Self, Value>
        where Value: Codable
}


@propertyWrapper
public final class ModelField<Base, Value>: AnyField, FieldRepresentable
    where Base: Model, Value: Codable
{
    public let key: String
    var outputValue: Value?
    var inputValue: DatabaseQuery.Value?

    public var field: ModelField<Base, Value> {
        return self
    }
    
    public var projectedValue: ModelField<Base, Value> {
        return self
    }
    
    public var wrappedValue: Value {
        get {
            if let value = self.inputValue {
                switch value {
                case .bind(let bind):
                    return bind as! Value
                case .default:
                    fatalError("Cannot access default field before it is initialized or fetched")
                default:
                    fatalError("Unexpected input value type: \(value)")
                }
            } else if let value = self.outputValue {
                return value
            } else {
                fatalError("Cannot access field before it is initialized or fetched")
            }
        }
        set {
            self.inputValue = .bind(newValue)
        }
    }

    public init(key: String) {
        self.key = key
    }

    // MARK: Property

    func output(from output: DatabaseOutput) throws {
        if output.contains(self.key) {
            self.inputValue = nil
            do {
                self.outputValue = try output.decode(self.key, as: Value.self)
            } catch {
                throw FluentError.invalidField(name: self.key, valueType: Value.self)
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.wrappedValue)
    }

    func decode(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let valueType = Value.self as? _Optional.Type {
            if container.decodeNil() {
                self.wrappedValue = (valueType._none as! Value)
            } else {
                self.wrappedValue = try container.decode(Value.self)
            }
        } else {
            self.wrappedValue = try container.decode(Value.self)
        }
    }
}


private protocol _Optional {
    static var _none: Any { get }
}
extension Optional: _Optional {
    static var _none: Any {
        return Self.none as Any
    }
}
