# Adding WeatherKit Framework to Xcode Project

## Steps to Add WeatherKit:

1. **Open your project in Xcode**
2. **Select your project** in the navigator (Haven2.0)
3. **Select your target** (Haven2.0)
4. **Go to "Signing & Capabilities" tab**
5. **Click "+ Capability"**
6. **Search for "WeatherKit"**
7. **Add "WeatherKit" capability**

## Add Location Permission to Info.plist:

1. **Right-click on your project** in Xcode
2. **Select "New File"**
3. **Choose "Property List"**
4. **Name it "Info.plist"**
5. **Add these keys:**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>TimeFlow needs location access to show weather conditions for your timeline.</string>
    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>TimeFlow needs location access to show weather conditions for your timeline.</string>
</dict>
</plist>
```

## Add WeatherKit Framework:

1. **Select your target** (Haven2.0)
2. **Go to "Build Phases" tab**
3. **Expand "Link Binary With Libraries"**
4. **Click "+"**
5. **Search for "WeatherKit.framework"**
6. **Add it**

## Alternative: Use Package Manager

1. **File → Add Package Dependencies**
2. **Search for "WeatherKit"**
3. **Add Apple's WeatherKit package**

After completing these steps, your WeatherKit integration will be ready!
