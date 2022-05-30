#pragma once

//! Std
#include <string> //> std::string
#include <vector> //> std::vector

//! Project
#include "atomicdex/utilities/cpprestsdk.utilities.hpp"

namespace atomic_dex::github_api
{
    // Request sent to fetch a GitHub repository's releases.
    struct repository_releases_request
    {
        std::string owner;
        std::string repository;
    };

    // Sends a request to GitHub to fetch every existing release of a valid repository.
    [[nodiscard]] pplx::task<web::http::http_response> get_repository_releases_async(const repository_releases_request& request);
    
    // GitHub repository release information.
    struct repository_release
    {
        std::string url;
        std::string assets_url;
        std::string name;
        std::string tag_name;
    };
    
    // Parses the http response returned by `get_repository_releases_async`. Be careful, resp must have returned 200.
    [[nodiscard]] std::vector<repository_release>   get_repository_releases_from_http_response(const web::http::http_response& resp);
    
    // Parses only the first release returned by `get_repository_releases_async`. Be careful, resp must have returned 200.
    [[nodiscard]] repository_release                get_last_repository_release_from_http_response(const web::http::http_response& resp);
    
    struct download_repository_release_request
    {
        std::string owner;
        std::string repository;
        std::string tag_name;
        std::string name;
    };
}
