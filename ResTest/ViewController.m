#import "ViewController.h"
#import "Display.h"


@interface ViewController () <NSTableViewDataSource, NSTableViewDelegate, NSWindowDelegate>

@property (nonatomic, weak) IBOutlet NSButton *showLowResButton;
@property (nonatomic, weak) IBOutlet NSTableView *resTableView;
@property (nonatomic, weak) IBOutlet NSTableView *depthsTableView;
@property (nonatomic, weak) IBOutlet NSPopUpButton *displayButton;

@property (nonatomic) Display *display;
@property (nonatomic) NSArray<DisplayMode *> *modes;
@property (nonatomic) NSArray<DisplayMode *> *notchedModes;

@property (nonatomic) NSMutableDictionary<Display *, DisplayMode *> *initialDisplayModesByDisplay;

@end


@implementation ViewController

+(BOOL)displayModeHeight:(size_t)suspectHeight isNotchedVersionOfHeight:(size_t)otherHeight
{
    if(suspectHeight <= otherHeight) return NO;

    size_t dy = suspectHeight - otherHeight;
    double dyAsPercentOfHeight = (double)dy / otherHeight;
//    NSLog(@"%zu vs %zu: %zu px / %.2lf", suspectHeight, otherHeight, dy, dyAsPercentOfHeight);
    return dyAsPercentOfHeight < 0.04;
}

+(void)removeNotchedHeightsFromSet:(NSMutableSet<NSNumber *> *)heights
{
    if(heights.count <= 1) return;

    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:NO];
    NSArray<NSSortDescriptor *> *sortDescriptors = @[ sortDescriptor ];

    NSArray<NSNumber *> *sortedHeights = [heights sortedArrayUsingDescriptors:sortDescriptors];
    for(NSUInteger i = 0; i < sortedHeights.count - 1; i++) {
        // Compare pairwise for notchness
        size_t bigger = [sortedHeights[i] unsignedIntegerValue];
        size_t smaller = [sortedHeights[i + 1] unsignedIntegerValue];
        if([self displayModeHeight:bigger isNotchedVersionOfHeight:smaller]) {
            // bigger needs to go.
            NSLog(@"height %zu is a notched version of %zu; removing it", bigger, smaller);
            [heights removeObject:@(bigger)];

            // We can skip smaller; it's accounted for as a notchless size
            i++;
        }
        else {
            // Legitimate res with the same width
            NSLog(@"height %zu and %zu will coexist", bigger, smaller);
        }
    }
}

+(NSArray<DisplayMode *> *)selectNotchedModes:(NSArray<DisplayMode *> *)modes
{
    NSMutableDictionary<NSNumber *, NSMutableSet<NSNumber *> *> *goodHeightsByWidth = [NSMutableDictionary new];

    /// Step 1: Collect all width x height combinations.
    for(DisplayMode *mode in modes) {
        size_t width = mode.width, height = mode.height;
        NSMutableSet<NSNumber *> *knownHeights = goodHeightsByWidth[@(width)];
        if(!knownHeights)
            goodHeightsByWidth[@(width)] = [NSMutableSet setWithObject:@(height)];
        else
            [knownHeights addObject:@(height)];
    }

    /// Step 2: Filter out heights that look like notched versions of
    /// resolutions with the same width.
    for(NSMutableSet<NSNumber *> *heights in goodHeightsByWidth.allValues)
        [self removeNotchedHeightsFromSet:heights];

    /// Step 3: Correlate the good dimensions with display modes.
    NSMutableArray *notchedModes = [NSMutableArray new];

    for(DisplayMode *mode in modes) {
        NSMutableSet *goodHeights = goodHeightsByWidth[@(mode.width)];
        if(![goodHeights containsObject:@(mode.height)])
            [notchedModes addObject:mode];
    }

    return notchedModes;
}

-(void)showErrorDialog:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2)
{
    va_list args;
    va_start(args, format);
    NSString *msg = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
//    NSLog(@"!!! %@", msg);

    NSAlert *alert = [NSAlert new];
    alert.messageText = msg;
    alert.alertStyle = NSAlertStyleCritical;
    [alert addButtonWithTitle:@"OK"];
    [alert beginSheetModalForWindow:self.view.window completionHandler:nil];
}

-(void)refreshDisplays
{
    [self.displayButton removeAllItems];

    NSArray<Display *> *displays = Display.activeDisplays;
    for(Display *display in displays) {
        NSMutableArray *notesBits = [NSMutableArray array];
        if(display.isMainDisplay) [notesBits addObject:@"main"];
        if(display.isBuiltIn) [notesBits addObject:@"built-in"];
        if(display.mightHaveNotch) [notesBits addObject:@"notch?"];
        NSString *notes = [notesBits componentsJoinedByString:@", "];

        if(notes.length) notes = [NSString stringWithFormat:@" (%@)", notes];
        NSString *desc = [NSString stringWithFormat:@"%@%@", display.name, notes];

        [self.displayButton addItemWithTitle:desc];
        self.displayButton.lastItem.representedObject = display;
    }
}

-(void)switchToDisplay:(Display *)display
{
    self.display = display;
    
    [self.depthsTableView reloadData];
    
    [self refreshModesIncludingLowRes:self.showLowResButton.state == NSControlStateValueOn];
    [self.resTableView reloadData];
}

-(void)switchToMode:(DisplayMode *)mode
{
    CGError err = [mode setAndCaptureDisplay:YES];
    if(err != kCGErrorSuccess) {
        [self showErrorDialog:@"Error switching display mode: %d", err];
        return;
    }

    if(!mode.isCurrentDisplayMode)
        NSLog(@"Switch was successful, but we're not in the expected mode!");

    self.view.window.level = CGShieldingWindowLevel() + 1;
    [self.view.window setFrame:NSMakeRect(0, 0, mode.width, mode.height)
                       display:YES];

    NSScreen *ourScreen = self.view.window.screen;

    NSLog(@"screen frame: %@", NSStringFromRect(ourScreen.frame));
    NSLog(@"screen visibleFrame: %@", NSStringFromRect(ourScreen.visibleFrame));

    if (@available(macOS 12.0, *)) {
        NSEdgeInsets insets = ourScreen.safeAreaInsets;
        NSLog(@"safeAreaInsets: %f %f %f %f", insets.top, insets.left, insets.bottom, insets.right);
    }
}

-(void)refreshModesIncludingLowRes:(BOOL)includeLowRes
{
    self.modes = [self.display displayModesIncludingLowRes:includeLowRes];
    
    if(self.display.mightHaveNotch)
        self.notchedModes = [ViewController selectNotchedModes:self.modes];
    else
        self.notchedModes = [NSArray array];
    
    [self.resTableView reloadData];
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.resTableView setTarget:self];
    [self.resTableView setDoubleAction:@selector(resTableViewDoubleClicked:)];
    
    [self refreshDisplays];
    [self switchToDisplay:Display.mainDisplay];

    // Stash initial display modes so we can restore them if asked.
    self.initialDisplayModesByDisplay = [NSMutableDictionary new];
    for(Display *display in Display.activeDisplays)
        [self.initialDisplayModesByDisplay setObject:display.currentDisplayMode forKey:display];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(screenParametersChanged:)
                                                 name:NSApplicationDidChangeScreenParametersNotification
                                               object:nil];
}

-(void)screenParametersChanged:(NSNotification *)note
{
    [self refreshDisplays];
}

-(void)viewDidAppear
{
    [super viewDidAppear];
    
    self.view.window.delegate = self;
}

-(NSApplicationPresentationOptions)window:(NSWindow *)window willUseFullScreenPresentationOptions:(NSApplicationPresentationOptions)proposedOptions
{
    return NSApplicationPresentationHideMenuBar | NSApplicationPresentationHideDock | NSApplicationPresentationFullScreen;
}

-(IBAction)showLowResToggled:(id)sender
{
    [self refreshModesIncludingLowRes:self.showLowResButton.state == NSControlStateValueOn];
}

-(IBAction)displayChanged:(id)sender
{
    Display *display = self.displayButton.selectedItem.representedObject;
    [self switchToDisplay:display];
}

-(IBAction)restoreInitialModesClicked:(id)sender
{
    for(Display *display in self.initialDisplayModesByDisplay) {
        DisplayMode *mode = self.initialDisplayModesByDisplay[display];
        CGError err = [mode setAndCaptureDisplay:NO];
        if(err == kCGErrorSuccess)
            [display uncapture];
        else
            NSLog(@"Error restoring initial mode %@ on %@: %d", mode, display, err);
    }

    [self.resTableView reloadData];
}

-(void)resTableViewDoubleClicked:(id)sender
{
    NSInteger row = self.resTableView.clickedRow;
    if(row == -1)
        return;

    [self switchToMode:self.modes[row]];
    
    [self.resTableView reloadData];
}

-(IBAction)copyFullReport:(id)sender
{
    NSMutableString *res = [NSMutableString new];
    [res appendFormat:@"Display %@\n\n", self.display.name];
    
    
    [res appendString:@"Supported Color Depths\n"];
    for(DisplayDepth *depth in self.display.depths) {
        [res appendFormat:@"%@\t%ld components\t%ld bpp\t\t%ld bits/sample\n",
         depth.colorSpaceName,
         (long)depth.numberOfColorComponents,
         (long)depth.bitsPerPixel,
         (long)depth.bitsPerSample];
    }
    [res appendString:@"\n"];
    
    
    [res appendString:@"Display Modes\n"];
    [res appendString:@"Index\tRes (pts)\t\tRes (px)\t\tRefresh\tDepth\tIO Flags\tFlags & Notes\n"];
    for(NSUInteger i = 0; i < self.modes.count; i++) {
        DisplayMode *mode = self.modes[i];

        [res appendFormat:@"%ld%@\t\t", i, mode.isCurrentDisplayMode ? @"*" : @""];
        [res appendFormat:@"%zu × %zu\t\t", mode.width, mode.height];
        [res appendFormat:@"%zu × %zu\t\t", mode.pixelWidth, mode.pixelHeight];
        [res appendFormat:@"%.1lf\t", mode.refreshRate];
        [res appendFormat:@"%lu\t\t", mode.bitsPerPixel];
        [res appendFormat:@"%#-9x\t", mode.ioFlags];
        
        NSString *notes = mode.ioFlagsDescription;
        
        if(!mode.isUsableForDesktopGUI)
            notes = [@"Not Usable for Desktop, " stringByAppendingString:notes];
        
        if([self.notchedModes containsObject:mode])
            notes = [@"Notched, " stringByAppendingString:notes];
        
        if(mode.isCurrentDisplayMode)
            notes = [@"Current, " stringByAppendingString:notes];
        
        [res appendFormat:@"%@\n", notes];
    }
    
    [[NSPasteboard generalPasteboard] clearContents];
    [[NSPasteboard generalPasteboard] setString:res forType:NSPasteboardTypeString];
}


#pragma mark NSTableView data source & delegate

-(NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    // Depths table
    if(tableView == self.depthsTableView)
        return self.display.depths.count;
    
    
    // Res table
    return self.modes.count;
}

-(NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    // Depths table
    if(tableView == self.depthsTableView) {
        DisplayDepth *depth = self.display.depths[row];
        NSString *text = @"";
        
        if([tableColumn.identifier isEqualToString:@"ColorSpaceCellID"])
            text = depth.colorSpaceName;
        else if([tableColumn.identifier isEqualToString:@"ComponentsCellID"])
            text = [NSString stringWithFormat:@"%ld", (long)depth.numberOfColorComponents];
        else if([tableColumn.identifier isEqualToString:@"BPPCellID"])
            text = [NSString stringWithFormat:@"%ld", (long)depth.bitsPerPixel];
        else if([tableColumn.identifier isEqualToString:@"BPSCellID"])
            text = [NSString stringWithFormat:@"%ld", (long)depth.bitsPerSample];
        
        NSTableCellView *view = [tableView makeViewWithIdentifier:tableColumn.identifier owner:nil];
        view.textField.stringValue = text;
        return view;
    }
    
    
    // Res table
    DisplayMode *mode = self.modes[row];
    NSString *text = @"";
    
    if([tableColumn.identifier isEqualToString:@"IndexCellID"])
        text = [NSString stringWithFormat:@"%ld%@", row, mode.isCurrentDisplayMode ? @" *" : @""];
    else if([tableColumn.identifier isEqualToString:@"PtResCellID"])
        text = [NSString stringWithFormat:@"%zu × %zu", mode.width, mode.height];
    else if([tableColumn.identifier isEqualToString:@"PxResCellID"])
        text = [NSString stringWithFormat:@"%zu × %zu", mode.pixelWidth, mode.pixelHeight];
    else if([tableColumn.identifier isEqualToString:@"RefreshCellID"])
        text = [NSString stringWithFormat:@"%.1lf", mode.refreshRate];
    else if([tableColumn.identifier isEqualToString:@"DepthCellID"])
        text = [NSString stringWithFormat:@"%lu", mode.bitsPerPixel];
    else if([tableColumn.identifier isEqualToString:@"FlagsCellID"])
        text = [NSString stringWithFormat:@"%#x", mode.ioFlags];
    else if([tableColumn.identifier isEqualToString:@"NotesCellID"]) {
        text = mode.ioFlagsDescription;
        if(mode.isCurrentDisplayMode)
            text = [@"Current, " stringByAppendingString:text];
        
        if([self.notchedModes containsObject:mode])
            text = [@"Notched, " stringByAppendingString:text];
        
        if(!mode.isUsableForDesktopGUI)
            text = [@"Not Usable for Desktop, " stringByAppendingString:text];
    }
    
    NSTableCellView *view = [tableView makeViewWithIdentifier:tableColumn.identifier owner:nil];
    view.textField.stringValue = text;

    if(mode.isCurrentDisplayMode)
        view.textField.font = [NSFont boldSystemFontOfSize:view.textField.font.pointSize];
    else
        view.textField.font = [NSFont systemFontOfSize:view.textField.font.pointSize];

    if((mode.ioFlags & (kDisplayModeSafeFlag | kDisplayModeValidFlag)) != (kDisplayModeSafeFlag | kDisplayModeValidFlag))
        view.textField.textColor = [NSColor systemRedColor];
    else
        view.textField.textColor = nil;
    
    return view;
}

@end
