//
//  CloudKitManager.swift
//  PetRescuePlanner
//
//  Created by Daniel Jin on 11/6/17.
//  Copyright © 2017 Daniel Rodosky. All rights reserved.
//

import Foundation
import CloudKit

class CloudKitManager {
    
    // Declare a public database for CKContainer.default
    let publicDatabase = CKContainer.default().publicCloudDatabase
    
    // MARK: - User Info Discovery
    
    func fetchLoggedInUserRecord(_ completion: ((_ record: CKRecord?, _ error: Error? ) -> Void)?) {
        
        CKContainer.default().fetchUserRecordID { (recordID, error) in
            
            if let error = error,
                let completion = completion {
                completion(nil, error)
            }
            
            if let recordID = recordID,
                let completion = completion {
                
                self.fetchRecord(withID: recordID, completion: completion)
            }
        }
    }
    
    
    
    func fetchUsername(for recordID: CKRecordID,
                       completion: @escaping ((_ givenName: String?, _ familyName: String?) -> Void) = { _,_ in }) {
        
        let recordInfo = CKUserIdentityLookupInfo(userRecordID: recordID)
        let operation = CKDiscoverUserIdentitiesOperation(userIdentityLookupInfos: [recordInfo])
        
        var userIdenties = [CKUserIdentity]()
        operation.userIdentityDiscoveredBlock = { (userIdentity, _) in
            userIdenties.append(userIdentity)
        }
        operation.discoverUserIdentitiesCompletionBlock = { (error) in
            if let error = error {
                NSLog("Error getting username from record ID: \(error)")
                completion(nil, nil)
                return
            }
            
            let nameComponents = userIdenties.first?.nameComponents
            completion(nameComponents?.givenName, nameComponents?.familyName)
        }
        
        CKContainer.default().add(operation)
    }
    
    func fetchAllDiscoverableUsers(completion: @escaping ((_ userInfoRecords: [CKUserIdentity]?) -> Void) = { _ in }) {
        
        let operation = CKDiscoverAllUserIdentitiesOperation()
        
        var userIdenties = [CKUserIdentity]()
        operation.userIdentityDiscoveredBlock = { userIdenties.append($0) }
        operation.discoverAllUserIdentitiesCompletionBlock = { error in
            if let error = error {
                NSLog("Error discovering all user identies: \(error)")
                completion(nil)
                return
            }
            
            completion(userIdenties)
        }
        
        CKContainer.default().add(operation)
    }
    
    // MARK: - Fetch methods
    func fetchRecord(withID recordID: CKRecordID, completion: ((_ record: CKRecord?, _ error: Error?) -> Void)?) {
        
        publicDatabase.fetch(withRecordID: recordID) { (record, error) in
            completion?(record, error)
        }
    }
    
    func fetchRecordsWithType(_ type: String,
                              predicate: NSPredicate = NSPredicate(value: true),
                              sortDescriptors: [NSSortDescriptor]? = nil,
                              recordFetchedBlock: @escaping (_ record: CKRecord) -> Void = { _ in },
                              completion: ((_ records: [CKRecord]?, _ error: Error?) -> Void)?) {
        
        var fetchedRecords: [CKRecord] = []
        
        let query = CKQuery(recordType: type, predicate: predicate)
        query.sortDescriptors = sortDescriptors
        let queryOperation = CKQueryOperation(query: query)
        
        let perRecordBlock = { (fetchedRecord: CKRecord) -> Void in
            fetchedRecords.append(fetchedRecord)
            recordFetchedBlock(fetchedRecord)
        }
        queryOperation.recordFetchedBlock = perRecordBlock
        
        var queryCompletionBlock: (CKQueryCursor?, Error?) -> Void = { (_, _) in }
        
        queryCompletionBlock = { (queryCursor: CKQueryCursor?, error: Error?) -> Void in
            
            if let queryCursor = queryCursor {
                // there are more results, go fetch them
                
                let continuedQueryOperation = CKQueryOperation(cursor: queryCursor)
                continuedQueryOperation.recordFetchedBlock = perRecordBlock
                continuedQueryOperation.queryCompletionBlock = queryCompletionBlock
                
                self.publicDatabase.add(continuedQueryOperation)
                
            } else {
                completion?(fetchedRecords, error)
            }
        }
        queryOperation.queryCompletionBlock = queryCompletionBlock
        
        self.publicDatabase.add(queryOperation)
    }
    
    func fetchRecordsWithType(_ type: String,
                              predicate: NSPredicate = NSPredicate(value: true),
                              recordFetchedBlock: ((_ record: CKRecord) -> Void)?,
                              completion: ((_ records: [CKRecord]?, _ error: Error?) -> Void)?) {
        
        var fetchedRecords: [CKRecord] = []
        
        let query = CKQuery(recordType: type, predicate: predicate)
        let queryOperation = CKQueryOperation(query: query)
        
        let perRecordBlock = { (fetchedRecord: CKRecord) -> Void in
            fetchedRecords.append(fetchedRecord)
            recordFetchedBlock?(fetchedRecord)
        }
        queryOperation.recordFetchedBlock = perRecordBlock
        
        var queryCompletionBlock: (CKQueryCursor?, Error?) -> Void = { (_, _) in }
        
        queryCompletionBlock = { (queryCursor: CKQueryCursor?, error: Error?) -> Void in
            
            if let queryCursor = queryCursor {
                // there are more results, go fetch them
                
                let continuedQueryOperation = CKQueryOperation(cursor: queryCursor)
                continuedQueryOperation.recordFetchedBlock = perRecordBlock
                continuedQueryOperation.queryCompletionBlock = queryCompletionBlock
                
                self.publicDatabase.add(continuedQueryOperation)
                
            } else {
                completion?(fetchedRecords, error)
            }
        }
        queryOperation.queryCompletionBlock = queryCompletionBlock
        
        self.publicDatabase.add(queryOperation)
    }
    
    // MARK: - Save methods
    func saveRecords(_ records: [CKRecord], perRecordCompletion: ((_ record: CKRecord?, _ error: Error?) -> Void)?, completion: ((_ records: [CKRecord]?, _ error: Error?) -> Void)?) {
        
        modifyRecords(records, perRecordCompletion: perRecordCompletion, completion: completion)
    }
    
    func save(_ record: CKRecord, completion: @escaping ((Error?) -> Void) = { _ in }) {
        
        // Call save on the database
        publicDatabase.save(record) { (record, error) in
            completion(error)
        }
    }
    
    // MARK: - Delete method
    func deleteRecordWithID(_ recordID: CKRecordID, completion: ((_ recordID: CKRecordID?, _ error: Error?) -> Void)?) {
        
        // Call delete on the database
        publicDatabase.delete(withRecordID: recordID) { (recordID, error) in
            completion?(recordID, error)
        }
    }
    
    func deleteRecordsWithID(_ recordIDs: [CKRecordID], completion: ((_ records: [CKRecord]?, _ recordIDs: [CKRecordID]?, _ error: Error?) -> Void)?) {
        
        let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDs)
        operation.savePolicy = .ifServerRecordUnchanged
        
        operation.modifyRecordsCompletionBlock = completion
        
        publicDatabase.add(operation)
    }
    
    // Flush delete Pet records
    func flushPetRecords() {
        let query = CKQuery(recordType: CloudKit.petRecordType, predicate: NSPredicate(value: true))
        
        publicDatabase.perform(query, inZoneWith: nil) { (records, error) in
            if error == nil {
                if let records = records {
                    self.deleteRecordsWithID(records.map{ $0.recordID }, completion: { (records, recordIDs, error) in
                        
                        if let error = error {
                            NSLog("Error deleting Pet records \(error.localizedDescription)")
                        }
                        
                    })
                }
            }
        }
    }
    
    // MARK: - Modify records
    func modifyRecords(_ records: [CKRecord], perRecordCompletion: ((_ record: CKRecord?, _ error: Error?) -> Void)?, completion: ((_ records: [CKRecord]?, _ error: Error?) -> Void)?) {
        
        let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        operation.savePolicy = .changedKeys
        operation.queuePriority = .high
        operation.qualityOfService = .userInteractive
        
        operation.perRecordCompletionBlock = perRecordCompletion
        
        operation.modifyRecordsCompletionBlock = { (records, recordIDs, error) -> Void in
            (completion?(records, error))!
        }
        publicDatabase.add(operation)
    }
}
