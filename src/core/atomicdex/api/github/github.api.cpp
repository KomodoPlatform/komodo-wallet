//! 3rdParty
#include <nlohmann/json.hpp>

//! Project
#include "github.api.hpp"

namespace atomic_dex::github_api
{
    const std::string api_remote_url{"https://api.github.com/"};
    const auto api_client = std::make_unique<web::http::client::http_client>(FROM_STD_STR(api_remote_url));
    const std::string github_url{"https://github.com/"};
    const auto github_client = std::make_unique<web::http::client::http_client>(FROM_STD_STR(github_url));

    pplx::task<web::http::http_response> get_repository_releases_async(const repository_releases_request& request)
    {
        web::http::http_request http_request;
        web::uri_builder        uri_builder;
    
        uri_builder.append_path(FROM_STD_STR("repos"));
        uri_builder.append_path(FROM_STD_STR(request.owner));
        uri_builder.append_path(FROM_STD_STR(request.repository));
        uri_builder.append_path(FROM_STD_STR("releases"));
        http_request.set_request_uri(uri_builder.to_uri());
        http_request.set_method(web::http::methods::GET);
        return api_client->request(http_request);
    }
    
    // Returns the asset element of the release which corresponds to your OS.
    const auto get_matching_os_asset = [](const nlohmann::json& answer)
    {
      for (auto& asset : answer.at("assets"))
      {
          std::string asset_download_url = asset.at("browser_download_url");
          
          if (asset_download_url.find(
#ifdef __APPLE__
              "osx.dmg"
#elif __linux__
              "linux.AppImage"
#elif _WIN32
              "windows.zip"
#endif
          ) != std::string::npos)
          {
              return asset;
          }
      }
      throw std::runtime_error("get_repository_releases_from_http_response: Cannot found a proper download url.");
    };
    
    std::vector<repository_release> get_repository_releases_from_http_response(const web::http::http_response& resp)
    {
        std::vector<repository_release> result{};
        const auto json_answer = nlohmann::json::parse(TO_STD_STR(resp.extract_string(true).get()));
        
        result.reserve(json_answer.size());
        for (auto& release_obj : json_answer)
        {
            const auto asset = get_matching_os_asset(release_obj);
            
            result.push_back(repository_release{
                                .url        = asset.at("browser_download_url"),
                                .assets_url = release_obj.at("assets_url"),
                                .name       = asset.at("name"),
                                .tag_name   = release_obj.at("tag_name")});
        }
        return result;
    }
    
    repository_release get_last_repository_release_from_http_response(const web::http::http_response& resp)
    {
        const std::string string_answer = TO_STD_STR(resp.extract_string(true).get());
        const auto json_answer = nlohmann::json::parse(string_answer);
        
        if (json_answer.empty())
        {
            return repository_release{};
        }
        
        const auto asset = get_matching_os_asset(json_answer.at(0));
        
        return repository_release{.url = asset.at("browser_download_url"), .assets_url = json_answer.at(0).at("assets_url"),
                                  .name = asset.at("name"), .tag_name   = json_answer.at(0).at("tag_name")};
    }
}
