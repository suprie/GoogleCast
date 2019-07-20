    //
    //  ContentView.swift
    //  Google Cast
    //
    //  Created by Supriyanto P on 18/07/19.
    //  Copyright © 2019 Supriyanto P. All rights reserved.
    //
    
    import SwiftUI
    import GoogleCast
    import Combine
    
    struct GoogleCastDevice {
        let name: String
        let uniqueId: String
        let status: String?

        
        init(gckDevice: GCKDevice) {
            name = gckDevice.friendlyName ?? "Unknown"
            uniqueId = gckDevice.uniqueID
            status = gckDevice.statusText
        }
    }
    
    class GoogleCastAdapter: NSObject, BindableObject {
        
        var didChange = PassthroughSubject<Void, Never>()
        
        var devices: [GCKDevice] = [GCKDevice]() {
            didSet {
                didChange.send()
            }
        }
        
        override init() {
            super.init()
            
            let gckCastContext = GCKCastContext.sharedInstance()
            
            gckCastContext.discoveryManager.add(self)
        }
    }
    
    extension GoogleCastAdapter: GCKDiscoveryManagerListener {
        func didStartDiscovery(forDeviceCategory deviceCategory: String) {
        }
        
        func didInsert(_ device: GCKDevice, at index: UInt) {
            devices.insert(device, at: Int(index))
        }
        
        func didUpdate(_ device: GCKDevice, at index: UInt) {
            devices.remove(at: Int(index))
            devices.insert(device, at: Int(index))
        }
        
        func didRemove(_ device: GCKDevice, at index: UInt) {
            devices.remove(at: Int(index))
        }
    }
    
    struct ContentView : View {
        @ObjectBinding var test = GoogleCastAdapter()
        
        var body: some View {
            List {
                ForEach(test.devices.identified(by: \.deviceID)) { device in
                    RowView(device: device)
                }
            }
        }
    }
    
    struct RowView: View {
        var device: GCKDevice
        
        var body: some View {
            Button(action: {
                GCKCastContext.sharedInstance().sessionManager.startSession(with: self.device)
                
                let metadata = GCKMediaMetadata()
                metadata.setString("Big Buck Bunny (2008)", forKey: kGCKMetadataKeyTitle)
                metadata.setString("Big Buck Bunny tells the story of a giant rabbit with a heart bigger than " +
                    "himself. When one sunny day three rodents rudely harass him, something " +
                    "snaps... and the rabbit ain't no bunny anymore! In the typical cartoon " +
                    "tradition he prepares the nasty rodents a comical revenge.",
                                   forKey: kGCKMetadataKeySubtitle)
                metadata.addImage(GCKImage(url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/BigBuckBunny.jpg")!,
                                           width: 480,
                                           height: 360))
                
                let url = URL.init(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")
                guard let mediaURL = url else {
                    print("invalid mediaURL")
                    return
                }
                
                let mediaInfoBuilder = GCKMediaInformationBuilder.init(contentURL: mediaURL)
                mediaInfoBuilder.streamType = GCKMediaStreamType.buffered;
                mediaInfoBuilder.contentType = "video/mp4"
                mediaInfoBuilder.metadata = metadata;
                let mediaInformation = mediaInfoBuilder.build()
                
                GCKCastContext.sharedInstance().sessionManager.currentSession?.remoteMediaClient?.loadMedia(mediaInformation)
            }, label: {
                VStack() {
                    Text(device.friendlyName ?? "")
                    Text(device.statusText ?? "")
                }

            })
        }
    }
    
    #if DEBUG
    struct ContentView_Previews : PreviewProvider {
        static var previews: some View {
            ContentView()
        }
    }
    #endif
