//
//  Content.swift
//  VisionCode
//
//  Created by Michael Crabtree on 2/3/24.
//

import Foundation


let longFile = """
type AssetSearchConnection {
  items: [AssetSearchResult!]!
  nextToken: String
}

type AssetSearchResult {
  thumbnailUrl: String!
  fullSizeUrl: String!
  thumbnailWidth: Float!
  thumbnailHeight: Float!
  width: Float!
  height: Float!
  assetType: AssetType
  searchIdentifier: ID!
}

enum AssetType {
  IMAGE
  GIF
}

enum AssetUpdateType {
  REMOVE_BACKGROUND
}


The `AWSDateTime` scalar type provided by AWS AppSync, represents a valid
***extended*** [ISO 8601 DateTime](https://en.wikipedia.org/wiki/ISO_8601#Combined_date_and_time_representations)
string. In other words, this scalar type accepts datetime strings of the form
`YYYY-MM-DDThh:mm:ss.SSSZ`.  The scalar can also accept "negative years" of the
form `-YYYY` which correspond to years before `0000`. For example,
"**-2017-01-01T00:00Z**" and "**-9999-01-01T00:00Z**" are both valid datetime
strings.  The field after the two digit seconds field is a nanoseconds field. It
can accept between 1 and 9 digits. So, for example,
"**1970-01-01T12:00:00.2Z**", "**1970-01-01T12:00:00.277Z**" and
"**1970-01-01T12:00:00.123456789Z**" are all valid datetime strings.  The
seconds and nanoseconds fields are optional (the seconds field must be specified
if the nanoseconds field is to be used).  The [time zone
offset](https://en.wikipedia.org/wiki/ISO_8601#Time_zone_designators) is
compulsory for this scalar. The time zone offset must either be `Z`
(representing the UTC time zone) or be in the format `±hh:mm:ss`. The seconds
field in the timezone offset will be considered valid even though it is not part
of the ISO 8601 standard.

scalar AWSDateTime


The `AWSEmail` scalar type provided by AWS AppSync, represents an Email address
string that complies with [RFC 822](https://www.ietf.org/rfc/rfc822.txt). For
example, "**username@example.com**" is a valid Email address.

scalar AWSEmail


The `AWSPhone` scalar type provided by AWS AppSync, represents a valid Phone
Number. Phone numbers are serialized and deserialized as Strings. Segments of
the phone number may be whitespace delimited or hyphenated.  The number can
specify a country code at the beginning. However, United States numbers without
country codes are still considered to be valid.

scalar AWSPhone

enum Badge {
  EMPLOYEE
  COMMUNITY_BUILDER
}

type Bounds {
  minX: Float!
  maxX: Float!
  minY: Float!
  maxY: Float!
}

input BoundsInput {
  minX: Float!
  maxX: Float!
  minY: Float!
  maxY: Float!
}

type Chat {
  id: ID!
  chatName: String
  memberships: [Membership!]!
  membershipConnection(limit: Int, nextToken: String): MembershipConnection!
  maxY: Float!
  maxFinalizedY: Float
  lastUpdated: AWSDateTime!
  lastActivity: AWSDateTime
  created: AWSDateTime!
  creator: PublicUser
  avatarViewUrl: String
  avatarAsset: ViewAsset
  styleMetadata: StyleMetadata!
  messageConnection(limit: Int, orderDescending: Boolean, orderBy: MessageOrder, nextToken: String): MessageConnection!
  presentUsersConnection(limit: Int): PresentUsersConnection!
  chatType: ChatType!
}

type ChatConnection {
  items: [Chat!]!
  nextToken: String
}

input ChatInput {
  id: String!
  chatName: String
  avatarFileId: String
  memberships: [MembershipInput!]
  styleMetadata: StyleMetadataInput
}

type ChatMessage {
  id: ID!
  creator: PublicUser!
  created: AWSDateTime!
  chat: Chat!
  chatId: ID!
  lastUpdated: AWSDateTime!
  contentType: ContentType!
  content: ChatMessageContent
  position: Position
  visible: Boolean!
  becameFinalized: AWSDateTime
  finalized: Boolean!
  displayAttribution: Boolean
}

union ChatMessageContent = TextContent | ImageContent | VideoContent | PenContent | EmbeddedLinkContent

union ChatMessageEvent = DeletedMessageEvent

input ChatMessageInput {
  id: ID!
  chatId: ID!
  contentType: ContentType
  textContent: TextContentInput
  imageContent: ImageContentInput
  videoContent: VideoContentInput
  penContent: PenContentInput
  embeddedLinkContent: EmbeddedLinkContentInput
  position: PositionInput
  visible: Boolean
  finalized: Boolean
}

enum ChatRole {
  CREATOR
  MODERATOR
}

enum ChatType {
  DM
  SCRAP
  GROUP
  PROFILE
}

type Config {
  needsUpgrade: UpgradeUrgency
}

input ContactInput {
  fullName: String!
  hashedPhoneNumber: String!
}

enum ContentType {
  TEXT
  IMAGE
  VIDEO
  PEN
  EMBEDDED_LINK
}

type DeletedMessageEvent {
  id: ID!
  chat: Chat!
  chatId: ID!
  creator: PublicUser!
}

input DeviceTokenInput {
  token: String!
  platform: Platform!
  bundleId: String
  deviceId: String
}

type EmbeddedLinkContent {
  caption: String
  url: String!
  title: String
  siteAttribution: String
  imageViewUrl: String
  imageAsset: ViewAsset
  style: Style
  imageAspect: Float
}

input EmbeddedLinkContentInput {
  caption: String
  url: String!
  title: String
  siteAttribution: String
  fileId: String
  style: StyleInput
  imageAspect: Float
}

type ImageContent {
  viewUrls: [String!]!
  assets: [ViewAsset!]!
  blurHashes: [String!]
  style: Style
}

input ImageContentInput {
  fileIds: [String!]!
  blurHashes: [String!]
  style: StyleInput
}

type Membership {
  chat: Chat!
  user: PublicUser!
  chatRoles: [ChatRole!]!
  lastReadChatMessageCreated: AWSDateTime
  created: AWSDateTime!
  side: Side!
  primaryStyle: Style
  notificationFrequency: NotificationFrequency!
  archived: Boolean
  pinned: Boolean
}

type MembershipConnection {
  items: [Membership!]!
  nextToken: String
}

input MembershipInput {
  chatId: ID
  userId: ID
  lastReadChatMessageCreated: AWSDateTime
  primaryStyle: StyleInput
  notificationFrequency: NotificationFrequency
  chatRoles: [ChatRole!]
  inviteCode: String
  archived: Boolean
  pinned: Boolean
}

type MessageConnection {
  items: [ChatMessage!]!
  nextToken: String
}

enum MessageOrder {
  BECAME_FINALIZED
  MAX_Y
}

type Mutation {
  createChat(input: ChatInput!): Chat!
  updateChat(input: ChatInput!): Chat!
  createMembership(input: MembershipInput!): Membership!
  deleteMembership(userId: ID!, chatId: ID!): ID!
  updateMembership(input: MembershipInput!): Membership!
  createInviteCode(chatId: ID!): String!
  putChatMessage(input: ChatMessageInput!): ChatMessage!
  deleteChatMessage(id: ID!, chatId: ID!): ChatMessageEvent!
  updateUser(input: UserInput!): PublicUser!
  createDeviceToken(input: DeviceTokenInput!): ID!
  deleteDeviceToken(tokenId: ID!): ID!
  importAsset(url: String!): ViewAsset!
  selectAsset(searchIdentifier: String!): ViewAsset!
  updateAsset(input: UpdateAssetInput!): ViewAsset!
  updateState(state: StateInput): AWSDateTime
  poke(userId: ID!, chatId: ID): ID!
  addContacts(input: [ContactInput!]!): ID!
  reportMessage(chatId: ID!, messageId: ID!): ID!
  confirmUser(username: String!): String!
  sendVerificationCode(username: String, identifier: String, type: VerificationType): VerificationType!
  verifyIdentifier(input: VerificationInput!): Boolean!
  resetPassword(input: ResetPasswordInput!): Boolean!
  createPresenceEvent(chatId: ID!, userId: ID!, action: PresenceAction!): PresenceEvent
}

enum NotificationFrequency {
  ALL
  NONE
}

type PenContent {
  penContent: [PenPath!]!
  startedDrawing: AWSDateTime
}

input PenContentInput {
  penContent: [PenPathInput!]!
}

type PenPath {
  d: String!
  fill: String
  strokeWidth: Float
}

input PenPathInput {
  d: String!
  fill: String
  strokeWidth: Float
}

enum Platform {
  WEB
  CHROME
  SAFARI
  IOS
  ANDROID
}

type Position {
  width: Float!
  height: Float!
  transform: [Float!]!
  autopositioned: Boolean!
  zIndex: Int
  bounds: Bounds
}

input PositionInput {
  width: Float!
  height: Float!
  transform: [Float!]
  autopositioned: Boolean
  zIndex: Int
  bounds: BoundsInput
}

enum PresenceAction {
  ENTERED_CHAT
  EXITED_CHAT
}

type PresenceEvent {
  userId: ID!
  chatId: ID!
  action: PresenceAction!
}

type PresentUsersConnection {
  items: [PublicUser]!
}

type PublicUser {
  id: ID!
  fullName: String!
  username: String!
  avatarViewUrl: String
  avatarAsset: ViewAsset
  primaryStyle: Style
  relationshipType: RelationshipType!
  profileChatId: ID!
  dmChatId: ID
  badges: [Badge!]
}

type PublicUserConnection {
  items: [PublicUser!]!
  nextToken: String
}

type Query {
  getLongRefreshToken: String
  getConfig(currentVersion: String!, platform: Platform!, bundleId: String!): Config!
  getUser: User!
  getUserById(id: ID!): PublicUser!
  getUsers(query: String, relationshipTypes: [RelationshipType!], relationshipType: RelationshipType, limit: Int, nextToken: String): PublicUserConnection!
  getChats(query: String, limit: Int, nextToken: String): ChatConnection!
  getChatById(id: ID!): Chat!
  getChatMessagesByIds(chatId: ID!, ids: [ID!]!): [ChatMessage]!
  getUploadUrl(fileId: ID!): String!
  searchAssets(query: String, transparent: Boolean, assetTypes: [AssetType!], nextToken: String): AssetSearchConnection!
  validateUserInputs(username: String): Boolean!
  randomlyFail: Boolean!
}

enum RelationshipType {
  FRIEND
  FRIEND_REQUEST_SENT
  FRIEND_REQUEST_RECEIVED
  FRIEND_REQUEST_REJECTED
  NONE
  BLOCK_SENT
  BLOCK_RECEIVED
  CONTACT
  IMPLIED_CONTACT
  FRIEND_OF_FRIEND
  SHARED_CHAT
}

input ResetPasswordInput {
  identifier: String
  username: String
  type: VerificationType!
  code: String!
  newPassword: String!
}

enum Side {
  LEFT
  RIGHT
}

input StateInput {
  currentChatId: ID
}

type Style {
  font: String!
  fontColor: String!
  bubbleColor: String!
}

input StyleInput {
  font: String!
  fontColor: String!
  bubbleColor: String!
}

type StyleMetadata {
  topPaddingForAutopositioning: Int!
  leftPaddingForAutopositioning: Int!
  attributionTextHeight: Int!
}

input StyleMetadataInput {
  topPaddingForAutopositioning: Int!
  leftPaddingForAutopositioning: Int!
  attributionTextHeight: Int!
}

type Subscription {
  chatMessageSubscription(chatId: ID!): ChatMessage
  chatMessageLog(chatId: ID!): ChatMessageEvent
  presenceUpdates(chatId: ID!): PresenceEvent
}

type TextContent {
  textContent: String!
  containsLinks: Boolean
  startedTyping: AWSDateTime
  style: Style
}

input TextContentInput {
  textContent: String!
  containsLinks: Boolean
  style: StyleInput
}

input UpdateAssetInput {
  fileId: ID!
  assetUpdateType: AssetUpdateType!
}

enum UpgradeUrgency {
  HARD
  SOFT
}

type User {
  id: ID!
  fullName: String!
  username: String!
  phoneNumber: AWSPhone
  phoneNumberVerified: AWSDateTime
  email: AWSEmail
  emailVerified: AWSDateTime
  avatarViewUrl: String
  avatarAsset: ViewAsset
  primaryStyle: Style
  membershipConnection(limit: Int, nextToken: String): MembershipConnection!
  badges: [Badge!]
  profileChatId: ID!
}

input UserInput {
  id: ID
  avatarFileId: String
  primaryStyle: StyleInput
  fullName: String
  relationshipType: RelationshipType
}

input VerificationInput {
  identifier: String
  username: String
  type: VerificationType!
  code: String!
}

enum VerificationType {
  PHONE_NUMBER
  EMAIL
}

type VideoContent {
  viewUrls: [String!]!
  assets: [ViewAsset!]!
}

input VideoContentInput {
  fileIds: [String!]!
}

type ViewAsset {
  fileId: ID!
  viewUrl: String!
  viewUrlExpiration: AWSDateTime
}

"""

let shortFile =
"""
//
//  DocumentView.swift
//  SwiftUITextEditor
//
//  Created by mark on 12/18/19.
//  Copyright © 2019 Swift Dev Journal. All rights reserved.
//

import SwiftUI

struct DocumentView: View {
    @State var document: Document
    var dismiss: () -> Void

    var body: some View {
        VStack {
            HStack {
                Text("File Name")
                    .foregroundColor(.secondary)

                Text(document.fileURL.lastPathComponent)
            }
            TextView(document: $document)
            Button("Done", action: dismiss)
        }
    }
}
"""

let randomFile =
"""
//
//  Model.swift
//  VisionCode
//
//  Created by Michael Crabtree on 1/26/24.
//

import Foundation

enum EditorError: LocalizedError {
    case serverError(Error)
    case encodingFailed
    
    var errorDescription: String? {
        switch (self) {
        case .encodingFailed:
            return "Encoding failed"
        case .serverError(let error):
            return "Server error \\(error)"
        }
    }
}
"""

let goFile =
"""
package commerce

import (
    "context"
    "fmt"

    logger "github.com/getfliff/common-go/instrumentation/log"
    "github.com/getfliff/fantasy-backend/internal/commerce/models"

    catalog "github.com/getfliff/fantasy-backend/internal/catalog/models"
)

type Service struct {
    repository Repository
    catalog    Catalog
    contest    Contest
}

type Catalog interface {
    GetProposals(ctx context.Context, IDs []string) ([]catalog.Proposal, error)
    GetLeaguesForProposals(ctx context.Context, proposalIDs []string) ([]catalog.League, error)
}

type Contest interface {
    ValidContestForPicks(ctx context.Context, proposalIDs []string) (string, error)
}

func (svc *Service) CreateCart(ctx context.Context, cartInput *models.CartInput) (*models.Cart, error) {
    log := logger.Get(ctx)
    cart, err := svc.repository.CreateCart(ctx, cartInput)

    if err != nil {
        log.Err(err).Msg("failed createCart")
        return nil, fmt.Errorf("failed to exec: %w", err)
    }

    return cart, nil
}

func (svc *Service) GetCart(ctx context.Context, cartInput *models.CartInput) (*models.Cart, error) {
    log := logger.Get(ctx)
    currentCart, err := svc.repository.GetCart(ctx, cartInput)

    if err != nil {
        log.Err(err).Msg("failed getCart")
        return nil, err
    }

    return currentCart, nil
}
func (svc *Service) CartProposals(ctx context.Context, cartID string) ([]catalog.Proposal, error) {
    cartProposals, err := svc.repository.CartProposals(ctx, cartID)
    if err != nil {
        return nil, fmt.Errorf("failed to get cart content: %w", err)
    }

    proposalIDs := make([]string, len(cartProposals))
    for i, proposal := range cartProposals {
        proposalIDs[i] = proposal.ProposalID
    }

    proposals, err := svc.catalog.GetProposals(ctx, proposalIDs)
    if err != nil {
        return nil, fmt.Errorf("failed to get proposals: %w", err)
    }

    return proposals, nil
}

func (svc *Service) IsValidCart(ctx context.Context, cart *models.Cart) (bool, error) {
    validatedCart, err := svc.ValidateCart(ctx, cart)
    if err != nil {
        return false, err
    }
    return validatedCart.IsValid, err
}

func (svc *Service) GetValidationErrorForCart(ctx context.Context, cart *models.Cart) (*string, error) {
    validatedCart, err := svc.ValidateCart(ctx, cart)
    if err != nil {
        return nil, err
    }
    return validatedCart.ValidationError, err
}
func (svc *Service) AddProposalsToCart(ctx context.Context, cartInput *models.CartInput, proposalIDs []string) (*models.Cart, error) {
    log := logger.Get(ctx)

    tx, err := svc.repository.BeginTx(ctx)
    defer func() {
        if tx != nil {
            _ = tx.Rollback(ctx)
        }
    }()
    if err != nil {
        log.Err(err).Msg("failed addProposalsToUsersCart: begin transaction failed")
        return nil, fmt.Errorf("failed to start tx: %w", err)
    }

    cart, err := svc.repository.GetCartTx(ctx, tx, cartInput)
    if err != nil {
        log.Err(err).Msg("failed addProposalsToUsersCart: get cart failed")
        return nil, fmt.Errorf("failed to get cart: %w", err)
    }

    if cart == nil {
        cart, err = svc.repository.CreateCartTx(ctx, tx, cartInput)
        if err != nil {
            log.Err(err).Msg("failed addProposalsToUsersCart: create cart failed")
            return nil, fmt.Errorf("failed to create cart: %w", err)
        }
    }

    err = svc.repository.AddProposalsToCartTx(ctx, tx, cart.ID, proposalIDs)
    if err != nil {
        log.Err(err).Msg("failed addProposalsToUsersCart: add proposals failed")
        return nil, fmt.Errorf("failed to add proposals: %w", err)
    }

    err = tx.Commit(ctx)
    if err != nil {
        log.Err(err).Msg("failed addProposalsToUsersCart: commit failed")
        return nil, fmt.Errorf("failed to commit: %w", err)
    }

    return cart, nil
}

func (svc *Service) RemoveProposalsFromCart(ctx context.Context, cartInput *models.CartInput, proposalIDs []string) (*models.Cart, error) {
    log := logger.Get(ctx)

    tx, err := svc.repository.BeginTx(ctx)
    defer func() {
        if tx != nil {
            _ = tx.Rollback(ctx)
        }
    }()
    if err != nil {
        log.Err(err).Msg("failed RemoveProposalsFromUserCart: begin transaction failed")
        return nil, fmt.Errorf("failed to exec: %w", err)
    }

    cart, err := svc.repository.GetCartTx(ctx, tx, cartInput)
    if err != nil {
        log.Err(err).Msg("failed RemoveProposalsFromUserCart: get cart failed")
        return nil, fmt.Errorf("failed to exec: %w", err)
    }

    if cart == nil {
        return nil, fmt.Errorf("no cart found for user")
    }

    err = svc.repository.RemoveProposalsFromCartTx(ctx, tx, cart.ID, proposalIDs)
    if err != nil {
        log.Err(err).Msg("failed RemoveProposalsFromUserCart: remove proposals failed")
        return nil, fmt.Errorf("failed to exec: %w", err)
    }

    err = tx.Commit(ctx)
    if err != nil {
        log.Err(err).Msg("failed RemoveProposalsFromUserCart: commit failed")
        return nil, fmt.Errorf("failed to exec: %w", err)
    }

    return cart, nil
}

func (svc *Service) CreateOrder(ctx context.Context, purchaseAmount float64, cartInput *models.CartInput) (*models.Order, error) {
    log := logger.Get(ctx)

    if purchaseAmount <= 0 {
        return nil, fmt.Errorf("invalid purchase amount: %f", purchaseAmount)
    }

    cart, err := svc.repository.GetCart(ctx, cartInput)
    if err != nil {
        log.Err(err).Msg("failed createOrder: get cart failed")
        return nil, fmt.Errorf("failed to get cart: %w", err)
    }

    cartProposals, err := svc.repository.CartProposals(ctx, cart.ID)
    if err != nil {
        log.Err(err).Msg("failed createOrder: get proposals failed")
        return nil, fmt.Errorf("failed to get proposals: %w", err)
    }

    // TODO: Validate the cart before creating the orders
    // validation, err := svc.validateCartPicks(ctx, proposals)
    // if err != nil {
    //     log.Err(err).Msg("failed createOrder: validate cart failed")
    //     return nil, fmt.Errorf("failed to validate cart: %w", err)
    // }
    // if validation.Error != nil {
    //     return nil, validation.Error
    // }

    // Now we validate that there is a contest that all proposals can enter into
    proposalIDs := make([]string, len(cartProposals))
    for i, proposal := range cartProposals {
        proposalIDs[i] = proposal.ProposalID
    }
    contestID, err := svc.contest.ValidContestForPicks(ctx, proposalIDs)
    if err != nil {
        log.Err(err).Msg("failed createOrder: get contest id failed")
        return nil, fmt.Errorf("failed to get contest id: %w", err)
    }

    // We call catalog to get the prices of the proposals.
    proposals, err := svc.catalog.GetProposals(ctx, proposalIDs)
    if err != nil {
        log.Err(err).Msg("failed createOrder: get proposlas failed")
        return nil, fmt.Errorf("failed to get proposals: %w", err)
    }

    // We can now create a validated order
    tx, err := svc.repository.BeginTx(ctx)
    if err != nil {
        log.Err(err).Msg("failed createOrder: begin transaction failed")
        return nil, fmt.Errorf("failed to start tx: %w", err)
    }
    defer func() {
        if err != nil {
            _ = tx.Rollback(ctx)
        }
    }()

    order, err := svc.repository.CreateOrderTx(ctx, tx, &CreateOrderInput{
        CartID:         cart.ID,
        PurchaseAmount: purchaseAmount,
        ContestID:      contestID,
    })
    if err != nil {
        log.Err(err).Msg("failed createOrder: create order failed")
        return nil, fmt.Errorf("failed to create order: %w", err)
    }

    // We copy the proposals from the cart to the order
    err = svc.repository.InsertProposalsIntoOrderTx(ctx, tx, order.ID, proposals)
    if err != nil {
        log.Err(err).Msg("failed createOrder: copy proposals failed")
        return nil, fmt.Errorf("failed to copy proposals: %w", err)
    }

    err = tx.Commit(ctx)
    if err != nil {
        log.Err(err).Msg("failed createOrder: commit failed")
        return nil, fmt.Errorf("failed to commit: %w", err)
    }

    return order, nil
}

"""
