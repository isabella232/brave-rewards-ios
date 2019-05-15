/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <Foundation/Foundation.h>
#import "Records.h"
#import "BATActivityInfoFilter.h"

NS_ASSUME_NONNULL_BEGIN

/// An interface into the ledger database
///
/// This class mirrors brave-core's `publisher_info_database.h/cc` file. This file will actually
/// likely be removed at a future date when database managment happens in the ledger library
@interface BATLedgerDatabase : NSObject

#pragma mark - Publisher Info

/// Get bare bones publisher info based on a publisher ID
+ (nullable BATPublisherInfo *)publisherInfoWithPublisherID:(NSString *)publisherID;

/// Get the publisher that will be displayed on the main brave rewards panel
+ (BATPublisherInfo *)panelPublisherWithFilter:(BATActivityInfoFilter *)filter;

/// Insert or update publisher info in the database given a BATPublisherInfo object
+ (void)insertOrUpdatePublisherInfo:(BATPublisherInfo *)info;

/// Restores all of the publishers to default excluded state
+ (void)restoreExcludedPublishers;

/// Get the number of publishers the user has excluded from Auto-Contribute
+ (NSUInteger)excludedPublishersCount;

#pragma mark - Contribution Info

/// Insert contribution info into the database given all the information for a contribution
+ (void)insertContributionInfo:(NSString *)probi
                         month:(const int)month
                          year:(const int)year
                          date:(const uint32_t)date
                  publisherKey:(NSString *)publisherKey
                      category:(BATRewardsCategory)category;

/// Get a list of publishers you have supported with one time tips given some month and year
+ (NSArray<BATPublisherInfo *> *)oneTimeTipsPublishersForMonth:(BATActivityMonth)month
                                                          year:(int)year;

#pragma mark - Activity Info

/// Insert or update activity info from a publisher
+ (void)insertOrUpdateActivityInfoFromPublisher:(BATPublisherInfo *)info;

/// Insert or update a set of activity info based on a set of publishers
+ (void)insertOrUpdateActivitiesInfoFromPublishers:(NSArray<BATPublisherInfo *> *)publishers;

/// Get a list of publishers with activity info given some start, limit and
/// filter
+ (NSArray<BATPublisherInfo *> *)publishersWithActivityFromOffset:(uint32_t)start
                                                            limit:(uint32_t)limit
                                                           filter:(nullable BATActivityInfoFilter *)filter;

/// Delete activity info for a publisher with a given ID and reconcile stamp
+ (void)deleteActivityInfoWithPublisherID:(NSString *)publisherID
                           reconcileStamp:(uint64_t)reconcileStamp;

#pragma mark - Media Publisher Info

/// Get a publisher linked with some media key
+ (nullable BATPublisherInfo *)mediaPublisherInfoWithMediaKey:(NSString *)mediaKey;

/// Insert or update some media info given some media key and publisher ID that it is linked to
+ (void)insertOrUpdateMediaPublisherInfoWithMediaKey:(NSString *)mediaKey
                                         publisherID:(NSString *)publisherID;

#pragma mark - Recurring Tips

/// Get a list of publishers you have supported with recurring tips given some month and year
+ (NSArray<BATPublisherInfo *> *)recurringTipsForMonth:(BATActivityMonth)month
                                                  year:(int)year;

/// Insert a recurring tip linked to a given publisher ID for some amount
+ (void)insertOrUpdateRecurringTipWithPublisherID:(NSString *)publisherID
                                           amount:(double)amount
                                        dateAdded:(uint32_t)dateAdded;

/// Remove a recurring tip linked to a given publisher ID
+ (BOOL)removeRecurringTipWithPublisherID:(NSString *)publisherID;

#pragma mark - Pending Contributions

/// Inserts a set of pending contributions from a contribution list
+ (void)insertPendingContributions:(BATPendingContributionList *)contributions;

/// Get the amount of BAT allocated for pending contributions
+ (double)reservedAmountForPendingContributions;

#pragma mark -

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
