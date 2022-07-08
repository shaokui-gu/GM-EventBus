import Foundation
import GM


open class GMEventBus {
    
    private struct Manager {
        static let instance = GMEventBus()
        static let queue = DispatchQueue(label: "com.gavin.eventbus", attributes: [])
    }
    
    private struct ObserverObj {
        let observer: NSObjectProtocol
        let name: String
    }
    
    private var observersCache = [UInt:[ObserverObj]]()
    
    open class func post(_ name: String, sender: Any? = nil, userInfo: [AnyHashable: Any]? = nil) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: name), object: sender, userInfo: userInfo)
    }
        
    open class func postToMainThread(_ name: String, sender: Any? = nil, userInfo: [AnyHashable: Any]? = nil) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name(rawValue: name), object: sender, userInfo: userInfo)
        }
    }
    
    @discardableResult
    open class func on(_ target: AnyObject, name: String, sender: Any? = nil, queue: OperationQueue?, handler: @escaping ((Notification?) -> Void)) -> NSObjectProtocol {
        let id = UInt(bitPattern: ObjectIdentifier(target))
        let observer = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: name), object: sender, queue: queue, using: handler)
        let namedObserver = ObserverObj(observer: observer, name: name)
        
        Manager.queue.sync {
            if let namedObservers = Manager.instance.observersCache[id] {
                Manager.instance.observersCache[id] = namedObservers + [namedObserver]
            } else {
                Manager.instance.observersCache[id] = [namedObserver]
            }
        }
        
        return observer
    }
    
    @discardableResult
    open class func onMainThread(_ target: AnyObject, name: String, sender: Any? = nil, handler: @escaping ((Notification?) -> Void)) -> NSObjectProtocol {
        return GMEventBus.on(target, name: name, sender: sender, queue: OperationQueue.main, handler: handler)
    }
    
    @discardableResult
    open class func onBackgroundThread(_ target: AnyObject, name: String, sender: Any? = nil, handler: @escaping ((Notification?) -> Void)) -> NSObjectProtocol {
        return GMEventBus.on(target, name: name, sender: sender, queue: OperationQueue(), handler: handler)
    }

    open class func unregister(_ target: AnyObject) {
        let id = UInt(bitPattern: ObjectIdentifier(target))
        let center = NotificationCenter.default
        
        Manager.queue.sync {
            if let namedObservers = Manager.instance.observersCache.removeValue(forKey: id) {
                for namedObserver in namedObservers {
                    center.removeObserver(namedObserver.observer)
                }
            }
        }
    }
    
    open class func unregister(_ target: AnyObject, name: String) {
        let id = UInt(bitPattern: ObjectIdentifier(target))
        let center = NotificationCenter.default
        
        Manager.queue.sync {
            if let namedObservers = Manager.instance.observersCache[id] {
                Manager.instance.observersCache[id] = namedObservers.filter({ (namedObserver: ObserverObj) -> Bool in
                    if namedObserver.name == name {
                        center.removeObserver(namedObserver.observer)
                        return false
                    } else {
                        return true
                    }
                })
            }
        }
    }
}

extension GM {
    
    public static func post(_ name: String, sender: Any? = nil, userInfo: [AnyHashable: Any]? = nil) {
        GMEventBus.post(name, sender: sender, userInfo: userInfo)
    }
    
    public static func postToMainThread(_ name: String, sender: Any? = nil, userInfo: [AnyHashable: Any]? = nil) {
        GMEventBus.postToMainThread(name, sender: sender, userInfo: userInfo)
    }
    
    public static func on(_ target: AnyObject, name: String, sender: Any? = nil, queue: OperationQueue?, handler: @escaping ((Notification?) -> Void)) -> NSObjectProtocol {
        GMEventBus.on(target, name: name, sender: sender, queue: queue, handler: handler)
    }
    
    public static func onMainThread(_ target: AnyObject, name: String, sender: Any? = nil, handler: @escaping ((Notification?) -> Void)) -> NSObjectProtocol {
        GMEventBus.onMainThread(target, name: name, sender: sender, handler: handler)
    }
    
    public static func onBackgroundThread(_ target: AnyObject, name: String, sender: Any? = nil, handler: @escaping ((Notification?) -> Void)) -> NSObjectProtocol {
        GMEventBus.onBackgroundThread(target, name: name, sender: sender, handler: handler)
    }
    
    public static func unregister(_ target: AnyObject) {
        GMEventBus.unregister(target)
    }
    
    public static func unregister(_ target: AnyObject, name: String) {
        GMEventBus.unregister(target, name: name)
    }
}


