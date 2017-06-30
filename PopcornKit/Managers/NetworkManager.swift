import Foundation
import Alamofire
import AlamofireImage

public struct Trakt {
    static let apiKey = "d3b0811a35719a67187cba2476335b2144d31e5840d02f687fbf84e7eaadc811"
    static let apiSecret = "f047aa37b81c87a990e210559a797fd4af3b94c16fb6d22b62aa501ca48ea0a4"
    static let base = "https://api.trakt.tv"
    static let shows = "/shows"
    static let movies = "/movies"
    static let people = "/people"
    static let person = "/person"
    static let seasons = "/seasons"
    static let episodes = "/episodes"
    static let auth = "/oauth"
    static let token = "/token"
    static let sync = "/sync"
    static let playback = "/playback"
    static let history = "/history"
    static let device = "/device"
    static let code = "/code"
    static let remove = "/remove"
    static let related = "/related"
    static let watched = "/watched"
    static let watchlist = "/watchlist"
    static let scrobble = "/scrobble"
    static let imdb = "/imdb"
    static let tvdb = "/tvdb"
    static let search = "/search"
    
    static let extended = ["extended": "full"]
    public struct Headers {
        static let Default = [
            "Content-Type": "application/json",
            "trakt-api-version": "2",
            "trakt-api-key": Trakt.apiKey
        ]
        
        static func Authorization(_ token: String) -> [String: String] {
            var Authorization = Default; Authorization["Authorization"] = "Bearer \(token)"
            return Authorization
        }
    }
    public enum MediaType: String {
        case movies = "movies"
        case shows = "shows"
        case episodes = "episodes"
        case people = "people"
    }
    /**
     Watched status of media.
     
     - .watching:   When the video intially starts playing or is unpaused.
     - .paused:     When the video is paused.
     - .finished:   When the video is stopped or finishes playing on its own.
     */
    public enum WatchedStatus: String {
        /// When the video intially starts playing or is unpaused.
        case watching = "start"
        /// When the video is paused.
        case paused = "pause"
        /// When the video is stopped or finishes playing on its own.
        case finished = "stop"
    }
}

public struct Popcorn {
    static let base = "https://tv-v2.api-fetch.website"
    static let shows = "/shows"
    static let movies = "/movies"

    static let movie = "/movie"
    static let show = "/show"
}

public struct TMDB {
    static let apiKey = "fa664b70ac6e307a1f859198f1148ce9"
    static let base = "https://api.themoviedb.org/3"
    static let tv = "/tv"
    static let person = "/person"
    static let images = "/images"
    static let season = "/season"
    static let episode = "/episode"
    
    public enum MediaType: String {
        case movies = "movie"
        case shows = "tv"
    }
    
    static let defaultHeaders = ["api_key": TMDB.apiKey]
}

public struct Fanart {
    static let apiKey = "bd2753f04538b01479e39e695308b921"
    static let base = "http://webservice.fanart.tv/v3"
    static let tv = "/tv"
    static let movies = "/movies"
    
    static let defaultParameters = ["api_key": Fanart.apiKey]
}

open class NetworkManager: NSObject {
    
    internal let manager: SessionManager = {
        
        var configuration = URLSessionConfiguration.default
        configuration.httpCookieAcceptPolicy = .always
        configuration.httpShouldSetCookies = true
        configuration.urlCache = PCTURLCache.default
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        
        return Alamofire.SessionManager(configuration: configuration)
    }()
    
    /// Possible orders used in API call.
    public enum Orders: Int {
        case ascending = 1
        case descending = -1
        
    }
    
    /// Possible genres used in API call.
    public enum Genres: String {
        case all = "All"
        case action = "Action"
        case adventure = "Adventure"
        case animation = "Animation"
        case comedy = "Comedy"
        case crime = "Crime"
        case disaster = "Disaster"
        case documentary = "Documentary"
        case drama = "Drama"
        case family = "Family"
        case fanFilm = "Fan Film"
        case fantasy = "Fantasy"
        case filmNoir = "Film Noir"
        case history = "History"
        case holiday = "Holiday"
        case horror = "Horror"
        case indie = "Indie"
        case music = "Music"
        case mystery = "Mystery"
        case road = "Road"
        case romance = "Romance"
        case sciFi = "Science Fiction"
        case short = "Short"
        case sports = "Sports"
        case sportingEvent = "Sporting Event"
        case suspense = "Suspense"
        case thriller = "Thriller"
        case war = "War"
        case western = "Western"
        
        public static var array = [all, action, adventure, animation, comedy, crime, disaster, documentary, drama, family, fanFilm, fantasy, filmNoir, history, holiday, horror, indie, music, mystery, road, romance, sciFi, short, sports, sportingEvent, suspense, thriller, war, western]
        
        public var string: String {
            return rawValue.localized
        }
    }
}

public extension ImageDownloader {
    
    public static let popcornTime: ImageDownloader = {
        PCTURLCache.default.customImageCaching = 86400
        return PCTURLCache.default.imageDownloader
    }()
    
}

public class PCTURLCache: URLCache {
    
    /// The default instance of `PCTURLCache` initialized with default values.
    public static let `default` = PCTURLCache(
        memoryCapacity: 20 * 1024 * 1024, // 20 MB
        diskCapacity: 150 * 1024 * 1024,  // 150 MB
        diskPath: nil
    )
    
    //MARK: ImageDownloader
    
    public lazy var imageDownloader: ImageDownloader =  {
        
        let cachePolicy: NSURLRequest.CachePolicy = .returnCacheDataElseLoad
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders     = SessionManager.defaultHTTPHeaders
        configuration.httpShouldSetCookies      = true
        configuration.httpShouldUsePipelining   = false
        
        configuration.requestCachePolicy        = .returnCacheDataElseLoad
        configuration.allowsCellularAccess      = true
        configuration.timeoutIntervalForRequest = 60
        
        configuration.urlCache                  = self
        
        let requestCache: ImageRequestCache = AutoPurgingImageCache()
        
        let imageDowloader = ImageDownloader(configuration: configuration,
                                             downloadPrioritization: .fifo,
                                             maximumActiveDownloads: 4,
                                             imageCache:requestCache )
        
        return imageDowloader
        
    }()
    
    //MARK: Let's see what happen here and add some custom caching by tricking the response
    
    public var customImageCaching: TimeInterval?
    
    override public func storeCachedResponse(_ cachedResponse: CachedURLResponse, for request: URLRequest) {
        
        // Fine grain image cache control
        if  let response = cachedResponse.response as? HTTPURLResponse,
            let url = response.url,
            let mimeType = response.mimeType,
            mimeType.substring(to:  mimeType.index( mimeType.startIndex, offsetBy: 5) ) == "image",
            let imageCaching = customImageCaching
            
        {
            
            var headers = response.allHeaderFields as! [String:String]
            
            headers["Cache-Control"] = "max-age=\(Int(imageCaching)),public"
            headers["Expires"]       = "\(Date() + imageCaching)"
            
            let updatedResponse = HTTPURLResponse(url:          url,
                                                  statusCode:   response.statusCode,
                                                  httpVersion:  nil,
                                                  headerFields: headers)
            
            let cached = CachedURLResponse(response: updatedResponse!,
                                           data: cachedResponse.data,
                                           userInfo: nil,
                                           storagePolicy: .allowed)
            
            super.storeCachedResponse(cached, for: request)
            return
        }
        
        super.storeCachedResponse(cachedResponse, for: request)
    }
    
}
