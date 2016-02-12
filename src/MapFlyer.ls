package
{
    import loom.modestmaps.extras.Distance;
    import loom.modestmaps.geo.Location;
    import loom.modestmaps.Map;
    import loom.modestmaps.mapproviders.IMapProvider;
    import loom.modestmaps.mapproviders.microsoft.MicrosoftRoadMapProvider;
    import loom2d.display.Graphics;
    import loom2d.display.Shape;
    import loom2d.display.TextAlign;
    import loom2d.display.TextFormat;
    import loom2d.math.Point;
    import system.platform.File;
    import system.platform.Platform;

    class Volcano {
        public var number:String;
        public var name:String;
        public var country:String;
        public var region:String;
        public var latitude:Number;
        public var longitude:Number;
        public var elevation:Number;
        public var type:String;
        public var status:String;
        public var lastEruption:String;
    }

    public class MapFlyer
    {
        private var sHelperPoint:Point;

        private var dt:Number = 1/60;

        private var map:Map;

        private var flyTarget:Location;
        private var flyPoint:Point;
        private var flySpeed:Number;
        private var nextLocation = new Location(0, 0);
        private var stopped:Boolean = true;

        public function MapFlyer(map:Map)
        {
            this.map = map;
        }

        public function flyTo(location:Location) {
            flyTarget = location;
            stopped = false;
            flySpeed = 0;
        }

        public function onTick()
        {
            if (stopped)
                return;

            var currentLocation:Location = map.getCenter();
            var currentZoom:Number = map.getZoomFractional();
            var dist = Distance.haversineDistance(currentLocation, flyTarget);

            var minZoom = 2;
            var maxZoom = 13.5;
            var zoomRange = maxZoom-minZoom;
            var zoomDist = 2e6;

            var moveSpeedMax = 10e6;

            var targetZoom = minZoom+(maxZoom-minZoom)*(1-Math.sqrt(Math.min2(1, dist/zoomDist)));

            var zoomDiff = targetZoom - currentZoom;

            sHelperPoint.x = map.getWidth() / 2;
            sHelperPoint.y = map.getHeight() / 2;

            var zoomSpeed = zoomDiff*0.3;
            var zoomDampen = Math.pow(1-Math.abs(zoomDiff/zoomRange), 4);

            var moveAccel = Math.min2((dist-flySpeed*0.9)*20, 50e6)*zoomDampen-flySpeed;

            flySpeed += moveAccel*dt;
            flySpeed *= 0.98;

            flySpeed = Math.min2(moveSpeedMax, flySpeed);

            flyPoint.x = flyTarget.lon-currentLocation.lon;
            flyPoint.y = flyTarget.lat-currentLocation.lat;
            flyPoint.normalize(1);

            // Speed in m/s to degrees/s
            flyPoint.x *= flySpeed/(111111*Math.cos(currentLocation.lat/180*Math.PI));
            flyPoint.y *= flySpeed/111111;

            var away = Math.abs(zoomDiff)*5*0.5+dist/100*0.5;

            nextLocation.lat = currentLocation.lat+flyPoint.y*dt;
            nextLocation.lon = currentLocation.lon+flyPoint.x*dt;

            map.panAndZoomBy(1+zoomSpeed*dt, nextLocation, sHelperPoint);

            if (away < 0.1) {
                stopped = true;
            }
        }
    }

}