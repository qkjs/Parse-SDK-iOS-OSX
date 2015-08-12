/**
 * Copyright (c) 2015-present, Parse, LLC.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "PFObject.h"
#import "PFUnitTestCase.h"
#import "Parse_Private.h"

@interface ObjectUnitTests : PFUnitTestCase

@end

@implementation ObjectUnitTests

///--------------------------------------
#pragma mark - Tests
///--------------------------------------

#pragma mark Constructors

- (void)testBasicConstructors {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    XCTAssertNotNil([[PFObject alloc] initWithClassName:@"Test"]);
    PFAssertThrowsInvalidArgumentException([[PFObject alloc] initWithClassName:nil]);

    XCTAssertNotNil([PFObject objectWithClassName:@"Test"]);
    PFAssertThrowsInvalidArgumentException([PFObject objectWithClassName:nil]);

    XCTAssertNotNil([PFObject objectWithoutDataWithClassName:@"Test" objectId:nil]);
    XCTAssertNotNil([PFObject objectWithoutDataWithClassName:@"Test" objectId:@"1"]);
    PFAssertThrowsInvalidArgumentException([PFObject objectWithoutDataWithClassName:nil objectId:nil]);
#pragma clang diagnostic pop
}

- (void)testConstructorsWithReservedClassNames {
    PFAssertThrowsInvalidArgumentException([[PFObject alloc] initWithClassName:@"_test"]);
    PFAssertThrowsInvalidArgumentException([PFObject objectWithClassName:@"_test"]);
    PFAssertThrowsInvalidArgumentException([PFObject objectWithoutDataWithClassName:@"_test" objectId:nil]);
}

- (void)testConstructorFromDictionary {
    XCTAssertNotNil([PFObject objectWithClassName:@"Test" dictionary:nil]);
    XCTAssertNotNil([PFObject objectWithClassName:@"Test" dictionary:@{}]);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    PFAssertThrowsInvalidArgumentException([PFObject objectWithClassName:nil dictionary:nil]);
#pragma clang diagnostic pop

    PFObject *object = [PFObject objectWithClassName:@"Test" dictionary:@{ @"a" : [NSDate date] }];
    XCTAssertNotNil(object);

    NSString *string = @"foo";
    NSNumber *number = @0.75;
    NSDate *date = [NSDate date];
    NSData *data = [@"foo" dataUsingEncoding:NSUTF8StringEncoding];
    NSNull *null = [NSNull null];
    NSDictionary *validDictionary = @{ @"string" : string,
                                       @"number" : number,
                                       @"date" : date,
                                       @"data" : data,
                                       @"null" : null,
                                       @"object" : object };
    PFObject *object2 = [PFObject objectWithClassName:@"Test" dictionary:validDictionary];
    XCTAssertNotNil(object2);
    XCTAssertEqualObjects(string, object2[@"string"], @"'string' should be set via constructor");
    XCTAssertEqualObjects(number, object2[@"number"], @"'number' should be set via constructor");
    XCTAssertEqualObjects(date, object2[@"date"], @"'date' should be set via constructor");
    XCTAssertEqualObjects(object, object2[@"object"], @"'object' should be set via constructor");
    XCTAssertEqualObjects(null, object2[@"null"], @"'null' should be set via constructor");
    XCTAssertEqualObjects(data, object2[@"data"], @"'data' should be set via constructor");

    validDictionary = @{ @"array" : @[ object, object2 ],
                         @"dictionary" : @{@"bar" : date, @"score" : number} };
    PFObject *object3 = [PFObject objectWithClassName:@"Stuff" dictionary:validDictionary];
    XCTAssertNotNil(object3);
    XCTAssertEqualObjects(validDictionary[@"array"], object3[@"array"], @"'array' should be set via constructor");
    XCTAssertEqualObjects(validDictionary[@"dictionary"], object3[@"dictionary"],
                         @"'dictionary' should be set via constructor");

    // Dictionary constructor relise on constraints enforced by PFObject -setObject:forKey:
    NSDictionary *invalidDictionary = @{ @"1" : @"2",
                                         @YES : @"foo" };
    PFAssertThrowsInvalidArgumentException([PFObject objectWithClassName:@"Test" dictionary:invalidDictionary]);
}

#pragma mark Accessors

- (void)testObjectForKey {
    PFObject *object = [PFObject objectWithClassName:@"Test"];
    object[@"yarr"] = @"yolo";
    XCTAssertEqualObjects([object objectForKey:@"yarr"], @"yolo");
    XCTAssertEqualObjects(object[@"yarr"], @"yolo");
}

- (void)testObjectForUnavailableKey {
    PFObject *object = [PFObject objectWithoutDataWithClassName:@"Yarr" objectId:nil];
    PFAssertThrowsInconsistencyException(object[@"yarr"]);
}

- (void)testSettersWithNilArguments {
    PFObject *object = [PFObject objectWithClassName:@"Test"];
    id empty = nil;

    PFAssertThrowsInvalidArgumentException([object setObject:@"foo" forKey:empty]);
    PFAssertThrowsInvalidArgumentException([object setObject:@"foo" forKeyedSubscript:empty]);
    PFAssertThrowsInvalidArgumentException(object[empty] = @"foo");

    PFAssertThrowsInvalidArgumentException([object setObject:empty forKey:@"foo"]);
    PFAssertThrowsInvalidArgumentException([object setObject:empty forKeyedSubscript:@"foo"]);
    PFAssertThrowsInvalidArgumentException(object[@"foo"] = empty);
}

- (void)testSettersWithInvalidValueTypes {
    PFObject *object = [PFObject objectWithClassName:@"Test"];

    NSSet *set = [NSSet set];
    PFAssertThrowsInvalidArgumentException([object setObject:set forKey:@"foo"]);
    PFAssertThrowsInvalidArgumentException([object setObject:set forKeyedSubscript:@"foo"]);
    PFAssertThrowsInvalidArgumentException(object[@"foo"] = set);
}

- (void)testArraySetters {
    PFObject *object = [PFObject objectWithClassName:@"Test"];

    [object addObject:@"yolo" forKey:@"yarr"];
    XCTAssertEqualObjects(object[@"yarr"], @[ @"yolo" ]);

    [object addObjectsFromArray:@[ @"yolo" ] forKey:@"yarr"];
    XCTAssertEqualObjects(object[@"yarr"], (@[ @"yolo", @"yolo" ]));

    [object addUniqueObject:@"yolo" forKey:@"yarrUnique"];
    [object addUniqueObject:@"yolo" forKey:@"yarrUnique"];
    XCTAssertEqualObjects(object[@"yarrUnique"], @[ @"yolo" ]);

    [object addUniqueObjectsFromArray:@[ @"yolo1" ] forKey:@"yarrUnique"];
    [object addUniqueObjectsFromArray:@[ @"yolo", @"yolo1" ] forKey:@"yarrUnique"];
    XCTAssertEqualObjects(object[@"yarrUnique"], (@[ @"yolo", @"yolo1" ]));

    object[@"removableYarr"] = @[ @"yolo" ];
    XCTAssertEqualObjects(object[@"removableYarr"], @[ @"yolo" ]);

    [object removeObject:@"yolo" forKey:@"removableYarr"];
    XCTAssertEqualObjects(object[@"removableYarr"], @[]);

    object[@"removableYarr"] = @[ @"yolo" ];
    [object removeObjectsInArray:@[ @"yolo", @"yolo1" ] forKey:@"removableYarr"];
    XCTAssertEqualObjects(object[@"removableYarr"], @[]);
}

- (void)testIncrement {
    PFObject *object = [PFObject objectWithClassName:@"Test"];

    [object incrementKey:@"yarr"];
    XCTAssertEqualObjects(object[@"yarr"], @1);

    [object incrementKey:@"yarr" byAmount:@2];
    XCTAssertEqualObjects(object[@"yarr"], @3);

    [object incrementKey:@"yarr" byAmount:@-2];
    XCTAssertEqualObjects(object[@"yarr"], @1);
}

- (void)testRemoveObjectForKey {
    PFObject *object = [PFObject objectWithClassName:@"Test"];
    object[@"yarr"] = @1;
    XCTAssertEqualObjects(object[@"yarr"], @1);

    [object removeObjectForKey:@"yarr"];
    XCTAssertNil(object[@"yarr"]);
}

- (void)testKeyValueCoding {
    PFObject *object = [PFObject objectWithClassName:@"Test"];
    [object setValue:@"yolo" forKey:@"yarr"];
    XCTAssertEqualObjects(object[@"yarr"], @"yolo");
    XCTAssertEqualObjects([object valueForKey:@"yarr"], @"yolo");
}

@end