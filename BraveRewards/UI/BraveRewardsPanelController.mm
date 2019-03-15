/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "BraveRewardsPanelController.h"
#import <BraveRewardsUI/BraveRewardsUI-Swift.h>

#import <BraveRewards/BATBraveLedger.h>
#import "BATBraveLedger+Private.h"

#import "bat/ledger/wallet_info.h"

#import "BraveRewardsTippingViewController.h"
#import "BraveRewardsSettingsViewController.h"

static const CGFloat kPreferredPanelWidth = 355.0;
static const CGFloat kPreferredPanelHeight = 574.0; // When viewing the wallet...

@interface BraveRewardsPanelController ()
@property (nonatomic) BATBraveLedger *ledger;
@property (readonly) BOOL isLocal;

@property (nonatomic) NSArray<NSLayoutConstraint *> *walletViewLayoutConstraints;
@property (nonatomic) WalletViewController *walletController;

// Wallet not created
@property (nonatomic) CreateWalletView *createWalletView;

// Brave Rewards not enabled
@property (nonatomic) RewardsDisabledView *rewardsDisabledView;

// Publisher
@property (nonatomic) PublisherSummaryView *publisherSummaryView;

@end

@implementation BraveRewardsPanelController

+ (UIImage *)batLogoImage
{
  return [UIImage imageNamed:@"bat" inBundle:[NSBundle bundleForClass:[CreateWalletView class]] compatibleWithTraitCollection:nil];
}

- (instancetype)initWithLedger:(BATBraveLedger *)ledger url:(NSURL *)url faviconURL:(NSURL *)faviconURL delegate:(id<BraveRewardsDelegate>)delegate dataSource:(id<BraveRewardsDataSource>)dataSource
{
  if ((self = [super initWithNibName:nil bundle:nil])) {
    self.ledger = ledger;
    self.url = url;
    self.faviconURL = faviconURL;
    self.dataSource = dataSource;
    self.delegate = delegate;
    
    self.walletController = [[WalletViewController alloc] init];
  }
  return self;
}

- (void)loadView
{
  self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kPreferredPanelWidth, kPreferredPanelHeight)];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.view.clipsToBounds = YES;
  
  [self.navigationController setNavigationBarHidden:YES animated:NO];
  
  [self.walletController.headerView.addFundsButton addTarget:self action:@selector(tappedAddFunds) forControlEvents:UIControlEventTouchUpInside];
  [self.walletController.headerView.settingsButton addTarget:self action:@selector(tappedSettings) forControlEvents:UIControlEventTouchUpInside];
  
  [self reloadState];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)updatePreferredSize
{
  [self.view layoutIfNeeded];
  auto size = [self.view systemLayoutSizeFittingSize:CGSizeMake(kPreferredPanelWidth, UIScreen.mainScreen.bounds.size.height)
                       withHorizontalFittingPriority:UILayoutPriorityRequired
                             verticalFittingPriority:UILayoutPriorityFittingSizeLevel];
  if (!self.ledger.walletCreated) {
    self.preferredContentSize = size;
  }
}

- (void)viewDidLayoutSubviews
{
  [super viewDidLayoutSubviews];
  
  if (self.ledger.isWalletCreated) {
    const auto scrollView = self.walletController.contentView.innerScrollView;
    CGFloat height = 0.0;
    if (scrollView) {
      scrollView.contentInset = UIEdgeInsetsMake(self.walletController.headerView.bounds.size.height, 0, 0, 0);
      scrollView.scrollIndicatorInsets = scrollView.contentInset;
      
      height = self.walletController.headerView.bounds.size.height + scrollView.contentSize.height + self.walletController.rewardsSummaryView.rewardsSummaryButton.bounds.size.height;
    } else {
      height = self.walletController.headerView.bounds.size.height + self.walletController.contentView.bounds.size.height + self.walletController.rewardsSummaryView.rewardsSummaryButton.bounds.size.height;
    }
    if (self.ledger.enabled) {
      height = kPreferredPanelHeight;
    }
    self.preferredContentSize = CGSizeMake(kPreferredPanelWidth, height);
  }
}

- (BOOL)isLocal
{
  return [self.url.host isEqualToString:@"127.0.0.1"] || [self.url.host isEqualToString:@"localhost"];
}

- (void)reloadState
{
  if (self.ledger.isWalletCreated) {
    ledger::WalletInfo _walletInfo; // FIXME: Obviously need real values
    _walletInfo.altcurrency_ = "BAT";
    _walletInfo.balance_ = 30.0;
    
    [self.walletController.headerView setWalletBalance:[NSString stringWithFormat:@"%.1f", _walletInfo.balance_]
                                                crypto:[NSString stringWithUTF8String:_walletInfo.altcurrency_.c_str()]
                                           dollarValue:@"0.00 USD"];
    
    [self addChildViewController:self.walletController];
    [self.walletController didMoveToParentViewController:self];
    [self.view addSubview:self.walletController.view];
    self.walletController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
      [self.walletController.view.topAnchor constraintEqualToAnchor:self.view.topAnchor],
      [self.walletController.view.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
      [self.walletController.view.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
      [self.walletController.view.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]
    ]];
    
    if (self.ledger.enabled) {
      self.publisherSummaryView = [[PublisherSummaryView alloc] init]; {
        self.publisherSummaryView.translatesAutoresizingMaskIntoConstraints = NO;
      }
      [self setupPublisher];
      self.walletController.contentView = self.publisherSummaryView;
    } else {
      self.rewardsDisabledView = [[RewardsDisabledView alloc] init]; {
        self.rewardsDisabledView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.rewardsDisabledView.enableRewardsButton addTarget:self action:@selector(tappedEnableBraveRewards) forControlEvents:UIControlEventTouchUpInside];
      }
      
      self.walletController.contentView = self.rewardsDisabledView;
    }
  } else {
    self.createWalletView = [[CreateWalletView alloc] init];
    self.createWalletView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.createWalletView.createWalletButton addTarget:self action:@selector(createWalletTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.createWalletView.learnMoreButton addTarget:self action:@selector(learnMoreTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.createWalletView];
    
    self.walletViewLayoutConstraints = @[
      [self.createWalletView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
      [self.createWalletView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
      [self.createWalletView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
      [self.createWalletView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    ];
    [NSLayoutConstraint activateConstraints:self.walletViewLayoutConstraints];
  }
  [self updatePreferredSize];
}

#pragma mark -

- (void)createWalletTapped
{
  self.createWalletView.isCreatingWallet = YES;
  [self.ledger createWallet:^(NSError * _Nullable error) {
    if (error) {
      self.createWalletView.isCreatingWallet = NO;
      const auto alertController = [UIAlertController alertControllerWithTitle:@"Error" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
      [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
      [self presentViewController:alertController animated:YES completion:nil];
      return;
    }
    [self.createWalletView removeFromSuperview];
    self.ledger.enabled = YES;
    [self reloadState];
  }];
}

- (void)tappedAddFunds
{
  
}

- (void)tappedSettings
{
  const auto settingsController = [[BraveRewardsSettingsViewController alloc] initWithLedger:self.ledger];
  [self showViewController:settingsController sender:self];
}

#pragma mark - Publisher

- (void)setupPublisher
{
  [self.publisherSummaryView.tipButton addTarget:self action:@selector(tappedSendTip) forControlEvents:UIControlEventTouchUpInside];
  
  const auto publisherView = self.publisherSummaryView.publisherView;
  const auto attentionView = self.publisherSummaryView.attentionView;
  
  [publisherView setVerificationStatusHidden:self.isLocal];
  
  // FIXME: Remove fake data
  [self.publisherSummaryView setLocal:self.isLocal];
  if (!self.isLocal) {
    publisherView.publisherNameLabel.text = self.url.host;
    [publisherView setVerifiedStatus:YES];
    attentionView.valueLabel.text = @"19%";
    
    const auto __weak weakSelf = self;
    [self.dataSource retrieveFaviconWithURL:self.faviconURL completion:^(UIImage * _Nullable image) {
      weakSelf.publisherSummaryView.publisherView.faviconImageView.image = image;
    }];
  }
}

- (void)tappedSendTip
{
  const auto controller = [[BraveRewardsTippingViewController alloc] initWithLedger:self.ledger
                                                                        publisherId:@""]; // TODO: Pass publisher id
  [self.delegate presentBraveRewardsController:controller];
}

#pragma mark - Create Wallet

- (void)learnMoreTapped
{
  
}

#pragma mark - Rewards Disabled

- (void)tappedEnableBraveRewards
{
  self.ledger.enabled = YES;
  [self reloadState];
}

@end
