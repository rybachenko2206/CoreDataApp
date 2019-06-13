//
//  CoreDataStack.swift
//  AppRealTestTask
//
//  Created by Roman Rybachenko on 6/13/19.
//  Copyright © 2019 Roman Rybachenko. All rights reserved.
//

import Foundation
import CoreData

class CoreDataStack {
    
    static let shared = CoreDataStack()
    private init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(mainContextChanged(notification:)),
                                               name: .NSManagedObjectContextDidSave,
                                               object: self.persistentContainer.viewContext)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(bgContextChanged(notification:)),
                                               name: .NSManagedObjectContextDidSave,
                                               object: self.backgroundContext)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Properties
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "AppRealTestTask")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    lazy var backgroundContext: NSManagedObjectContext = {
        return self.persistentContainer.newBackgroundContext()
    }()
    
    lazy var mainContext: NSManagedObjectContext = {
        return self.persistentContainer.viewContext
    }()
    
    
    // MARK: Notification observers
    
    @objc func mainContextChanged(notification: Notification) {
        backgroundContext.perform {
            self.backgroundContext.mergeChanges(fromContextDidSave: notification)
        }
    }
    @objc func bgContextChanged(notification: Notification) {
        mainContext.perform {
            self.mainContext.mergeChanges(fromContextDidSave: notification)
        }
    }
    
    
    // MARK: - Public funcs
    func saveContext(_ context: NSManagedObjectContext) {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    
    func addInitialPersons() {
        let bgContext = self.backgroundContext
        guard let plistPath = Bundle.main.path(forResource: "Persons", ofType: "plist"),
            let dictionary = NSDictionary.init(contentsOfFile: plistPath),
            let personsArr = dictionary["Persons"] as? [[String: Any]] else { return }
        
        personsArr.forEach({ dict in
            let name = dict["name"] as? String ?? ""
            let avatarName = dict["avatarName"] as? String ?? ""
            let _ = Person.newPerson(name: name, avatarName: avatarName, context: bgContext)
        })
        self.saveContext(bgContext)
    }
    
}
