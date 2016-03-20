import Foundation

internal protocol MutableCollectionSectionProtocol {
    func _getSubsection(atIndex _: Int) throws -> MutableCollectionSectionProtocol
    func _getItem<Z>(atIndexPath _: [Int]) throws -> Z
    func _removeItem<Z>(atIndexPath _: [Int]) throws -> Z
    mutating func _insert<Z>(_: Z, atIndexPath _: [Int]) throws
}

public enum MutableCollectionSectionError: ErrorType {
    case CantGetChild(type: String)
    case CantCastValue(type: String, targetType: String)
    case CantInsertElementOfType(elementType: String, sectionType: String)
    
    var description: String {
        switch self {
        case .CantGetChild(type: let type):
            return "Can't get child of an element of type \(type)"
        case .CantCastValue(type: let type, targetType: let targetType):
            return "Cannot cast value of type \(type) to \(targetType)"
        case .CantInsertElementOfType(elementType: let elementType, sectionType: let sectionType):
            return "Attempt to inset element of type \(elementType) in section of type \(sectionType)"
            
        }
    }
}

public class MutableCollectionSection<T>: MutableCollectionSectionProtocol {
    
    internal var _items: [T]
    
    init (_ items: [T]) {
        self._items = items
    }
    
    public var items: [T] {
        return self._items
    }
    
    public var count: Int {
        return self._items.count
    }
    
    public subscript(index: Int) -> T {
        return self._items[index]
    }
    
    
    // MARK: - Internal methods
    
    internal func _getSubsection(atIndex index: Int) throws -> MutableCollectionSectionProtocol {
        guard let section = self._items[index] as? MutableCollectionSectionProtocol else {
            throw MutableCollectionSectionError.CantGetChild(type: String(self._items[index].dynamicType))
        }
        return section
    }
    
    internal func _insert<Z>(el: Z, atIndexPath indexPath: [Int]) throws {
        if indexPath.count > 1 {
            var section = try self._getSubsection(atIndex: indexPath.first!)
            let range = Range(start: indexPath.first!, end: indexPath.first! + 1)
            try section._insert(el, atIndexPath: Array(indexPath.dropFirst()))
            return self._items.replaceRange(range, with: [section as! T])
        }
        guard let elT = el as? T else {
            let elementType = String(el.dynamicType)
            let sectionType = String(T.self)
            throw MutableCollectionSectionError.CantInsertElementOfType(elementType: elementType, sectionType: sectionType)
        }
        self._items.insert(elT, atIndex: indexPath.first!)
    }
    
    internal func _getItem<Z>(atIndexPath indexPath: [Int]) throws -> Z {
        if indexPath.count > 1 {
            let section = try self._getSubsection(atIndex: indexPath.first!)
            return try section._getItem(atIndexPath: Array(indexPath.dropFirst()))
        }
        guard let result = self._items[indexPath.first!] as? Z else {
            let type = String(self._items[indexPath.first!].dynamicType)
            let targetType = String(Z.self)
            throw MutableCollectionSectionError.CantCastValue(type: type, targetType: targetType)
        }
        return result
    }
    
    internal func _removeItem<Z>(atIndexPath indexPath: [Int]) throws -> Z {
        if indexPath.count > 1 {
            let section = try self._getSubsection(atIndex: indexPath.first!)
            return try section._removeItem(atIndexPath: Array(indexPath.dropFirst()))
        }
        let deletedElement = self._items.removeAtIndex(indexPath.first!)
        guard let deletedElementZ = deletedElement as? Z else {
            let type = String(deletedElement.dynamicType)
            let targetType = String(Z.self)
            throw MutableCollectionSectionError.CantCastValue(type: type, targetType: targetType)
        }
        return deletedElementZ
    }
    
}

public func ==<T: Equatable>(a: MutableCollectionSection<T>, b: MutableCollectionSection<T>) -> Bool {
    return a._items == b._items
}
