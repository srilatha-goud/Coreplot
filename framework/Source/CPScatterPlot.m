
#import "CPScatterPlot.h"
#import "CPLineStyle.h"
#import "CPPlotSpace.h"
#import "CPExceptions.h"

NSString *CPScatterPlotBindingXValues = @"xValues";
NSString *CPScatterPlotBindingYValues = @"yValues";

static NSString *CPXValuesBindingContext = @"CPXValuesBindingContext";
static NSString *CPYValuesBindingContext = @"CPYValuesBindingContext";


@interface CPScatterPlot ()

@property (nonatomic, readwrite, retain) id observedObjectForXValues;
@property (nonatomic, readwrite, retain) id observedObjectForYValues;
@property (nonatomic, readwrite, copy) NSString *keyPathForXValues;
@property (nonatomic, readwrite, copy) NSString *keyPathForYValues;

@end


@implementation CPScatterPlot

@synthesize numericType;
@synthesize observedObjectForXValues;
@synthesize observedObjectForYValues;
@synthesize keyPathForXValues;
@synthesize keyPathForYValues;
@synthesize hasErrorBars;
@synthesize dataLineStyle;

#pragma mark -
#pragma mark init/dealloc

+(void)initialize
{
    [self exposeBinding:CPScatterPlotBindingXValues];	
    [self exposeBinding:CPScatterPlotBindingYValues];	
}

-(id)init
{
    if (self = [super init]) {
        self.numericType = CPNumericTypeFloat;
		self.dataLineStyle = [CPLineStyle lineStyle];
    }
    return self;
}



-(void)dealloc
{
    if ( self.keyPathForXValues ) [self unbind:CPScatterPlotBindingXValues];
    if ( self.keyPathForYValues ) [self unbind:CPScatterPlotBindingYValues];
    [super dealloc];
}


-(void)bind:(NSString *)binding toObject:(id)observable withKeyPath:(NSString *)keyPath options:(NSDictionary *)options
{
    [super bind:binding toObject:observable withKeyPath:keyPath options:options];
    if ([binding isEqualToString:CPScatterPlotBindingXValues]) {
        [observable addObserver:self forKeyPath:keyPath options:0 context:CPXValuesBindingContext];
        self.observedObjectForXValues = observable;
        self.keyPathForXValues = keyPath;
    }
    else if ([binding isEqualToString:CPScatterPlotBindingYValues]) {
        [observable addObserver:self forKeyPath:keyPath options:0 context:CPYValuesBindingContext];
        self.observedObjectForYValues = observable;
        self.keyPathForYValues = keyPath;
    }
    [self setNeedsDisplay];
}


-(void)unbind:(NSString *)bindingName
{
    if ([bindingName isEqualToString:CPScatterPlotBindingXValues]) {
		[observedObjectForXValues removeObserver:self forKeyPath:keyPathForXValues];
        self.observedObjectForXValues = nil;
        self.keyPathForXValues = nil;
    }	
    else if ([bindingName isEqualToString:CPScatterPlotBindingYValues]) {
		[observedObjectForYValues removeObserver:self forKeyPath:keyPathForYValues];
        self.observedObjectForYValues = nil;
        self.keyPathForYValues = nil;
    }	
	[super unbind:bindingName];
	[self setNeedsDisplay];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == CPXValuesBindingContext) {
        [self setNeedsDisplay];
    }
    if (context == CPYValuesBindingContext) {
        [self setNeedsDisplay];
    }
}

#pragma mark -
#pragma mark Drawing

-(void)renderAsVectorInContext:(CGContextRef)theContext
{
	NSUInteger ii;
	NSArray *xData = [self.observedObjectForXValues valueForKeyPath:self.keyPathForXValues];
	NSArray *yData = [self.observedObjectForYValues valueForKeyPath:self.keyPathForYValues];
	CGMutablePathRef dataLine = CGPathCreateMutable();

	// Temporary storage for the viewPointForPlotPoint call
	NSMutableArray* plotPoint = [NSMutableArray array];
	CGPoint viewPoint;

	if ([xData count] != [yData count])
		[NSException raise:CPException format:@"Number of x and y values do not match"];
	
	if ([xData count] > 0)
	{
		[plotPoint insertObject:[xData objectAtIndex:0] atIndex:0];
		[plotPoint insertObject:[yData objectAtIndex:0] atIndex:1];
		viewPoint = [plotSpace viewPointForPlotPoint:plotPoint];
		
		CGPathMoveToPoint(dataLine, NULL, viewPoint.x, viewPoint.y);
		[plotPoint removeAllObjects];
	}

	for (ii = 1; ii < [xData count]; ii++)
	{
		[plotPoint insertObject:[xData objectAtIndex:ii] atIndex:0];
		[plotPoint insertObject:[yData objectAtIndex:ii] atIndex:1];
		viewPoint = [plotSpace viewPointForPlotPoint:plotPoint];
		
		CGPathAddLineToPoint(dataLine, NULL, viewPoint.x, viewPoint.y);
		[plotPoint removeAllObjects];
	}
	CGContextBeginPath(theContext);
	CGContextAddPath(theContext, dataLine);
	[dataLineStyle setLineStyleInContext:theContext];
    CGContextStrokePath(theContext);
	
	CGPathRelease(dataLine);
		
}

@end
