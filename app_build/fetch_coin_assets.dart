// ignore_for_file: avoid_print, unreachable_from_main
// TODO(Francois): Split this file into multiple files once the build system is finalised
// TODO(Francois): Change print statements to Log statements

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

// Entry point
const String defaultBuildConfigPath = 'assets/runtime_updates.json';

Future<void> main(List<String> arguments) async {
  final ReceivePort receivePort = ReceivePort();
  final CoinCIConfig config = CoinCIConfig.loadSync(defaultBuildConfigPath);
  final GitHubFileDownloader downloader = GitHubFileDownloader(
    repoApiUrl: config.coinsRepoApiUrl,
    repoContentUrl: config.coinsRepoContentUrl,
    sendPort: receivePort.sendPort,
  );

  receivePort.listen(
    (dynamic message) => onProgressData(message, receivePort),
    onError: onProgressError,
  );

  await downloader.download(
    config.bundledCoinsRepoCommit,
    config.mappedFiles,
    config.mappedFolders,
  );
}

void onProgressError(dynamic error) {
  print('\nError: $error');
}

void onProgressData(dynamic message, ReceivePort? recevePort) {
  if (message is BuildProgressMessage) {
    stdout.write(
      '\r${message.message} - Progress: ${message.progress.toStringAsFixed(2)}% \x1b[K',
    );

    if (message.progress == 100 && message.finished) {
      recevePort?.close();
    }
  }
}

// Data models

/// Represents the build configuration for fetching coin assets.
class CoinCIConfig {
  /// Creates a new instance of [CoinCIConfig].
  CoinCIConfig({
    required this.bundledCoinsRepoCommit,
    required this.coinsRepoApiUrl,
    required this.coinsRepoContentUrl,
    required this.coinsRepoBranch,
    required this.runtimeUpdatesEnabled,
    required this.mappedFiles,
    required this.mappedFolders,
  });

  /// Creates a new instance of [CoinCIConfig] from a JSON object.
  factory CoinCIConfig.fromJson(Map<String, dynamic> json) {
    return CoinCIConfig(
      bundledCoinsRepoCommit: json['bundled_coins_repo_commit'].toString(),
      coinsRepoApiUrl: json['coins_repo_api_url'].toString(),
      coinsRepoContentUrl: json['coins_repo_content_url'].toString(),
      coinsRepoBranch: json['coins_repo_branch'].toString(),
      runtimeUpdatesEnabled: json['runtime_updates_enabled'] as bool,
      mappedFiles: Map<String, String>.from(
        json['mapped_files'] as Map<String, dynamic>,
      ),
      mappedFolders: Map<String, String>.from(
        json['mapped_folders'] as Map<String, dynamic>,
      ),
    );
  }

  /// Converts the [CoinCIConfig] instance to a JSON object.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'bundled_coins_repo_commit': bundledCoinsRepoCommit,
        'coins_repo_api_url': coinsRepoApiUrl,
        'coins_repo_content_url': coinsRepoContentUrl,
        'coins_repo_branch': coinsRepoBranch,
        'runtime_updates_enabled': runtimeUpdatesEnabled,
        'mapped_files': mappedFiles,
        'mapped_folders': mappedFolders,
      };

  /// The commit hash of the bundled coins assets.
  final String bundledCoinsRepoCommit;

  /// The GitHub API of the coins repository.
  final String coinsRepoApiUrl;

  /// The GitHub Content URL of the coins repository.
  final String coinsRepoContentUrl;

  /// The branch of the coins repository to use for fetching assets.
  final String coinsRepoBranch;

  /// Indicates whether runtime updates of the coins assets are enabled.
  final bool runtimeUpdatesEnabled;

  /// A map of mapped files to download.
  /// The keys represent the local paths where the files will be saved,
  /// and the values represent the relative paths of the files in the repository.
  final Map<String, String> mappedFiles;

  /// A map of mapped folders to download. The keys represent the local paths
  /// where the folders will be saved, and the values represent the corresponding
  /// paths in the GitHub repository.
  final Map<String, String> mappedFolders;

  /// Loads the coins configuration synchronously from the specified [path].
  ///
  /// Prints the path from which the coins configuration is being loaded.
  /// Reads the contents of the file at the specified path and decodes it as JSON.
  /// If the 'coins' key is not present in the decoded data, prints an error message and exits with code 1.
  /// Returns a [CoinCIConfig] object created from the decoded 'coins' data.
  static CoinCIConfig loadSync(String path) {
    print('Loading coins config from $path');
    final File file = File(path);
    final String contents = file.readAsStringSync();
    final Map<String, dynamic> data =
        jsonDecode(contents) as Map<String, dynamic>;
    return CoinCIConfig.fromJson(data);
  }

  /// Saves the coins configuration to the specified asset path and optionally updates the build configuration file.
  ///
  /// The [assetPath] parameter specifies the path where the coins configuration will be saved.
  /// The [buildConfigPath] parameter specifies the path of the build configuration file.
  /// The [updateBuildConfig] parameter indicates whether to update the build configuration file or not.
  ///
  /// If [updateBuildConfig] is `true`, the coins configuration will also be saved to the build configuration file specified by [buildConfigPath].
  ///
  /// Throws an exception if any error occurs during the saving process.
  Future<void> save({
    required String assetPath,
    required String buildConfigPath,
    bool updateBuildConfig = true,
  }) async {
    final List<String> foldersToCreate = <String>[
      path.dirname(assetPath),
      path.dirname(buildConfigPath),
    ];
    createFolders(foldersToCreate);

    print('Saving coins config to $assetPath');
    final String data = jsonEncode(toJson());
    await File(assetPath).writeAsString(data);

    if (updateBuildConfig) {
      print('Saving coins config to $buildConfigPath');
      final File file = File(buildConfigPath);
      final String contents = await file.readAsString();
      final Map<String, dynamic> jsonData =
          jsonDecode(contents) as Map<String, dynamic>;
      jsonData['coins'] = toJson();
      await file.writeAsString(jsonEncode(jsonData));
    }
  }
}

/// Represents a file on GitHub.
class GitHubFile {
  /// Creates a new instance of [GitHubFile].
  const GitHubFile({
    required this.name,
    required this.path,
    required this.sha,
    required this.size,
    this.url,
    this.htmlUrl,
    this.gitUrl,
    required this.downloadUrl,
    required this.type,
    this.links,
  });

  /// Creates a new instance of [GitHubFile] from a JSON map.
  factory GitHubFile.fromJson(Map<String, dynamic> data) => GitHubFile(
        name: data['name'] as String,
        path: data['path'] as String,
        sha: data['sha'] as String,
        size: data['size'] as int,
        url: data['url'] as String?,
        htmlUrl: data['html_url'] as String?,
        gitUrl: data['git_url'] as String?,
        downloadUrl: data['download_url'] as String,
        type: data['type'] as String,
        links: data['_links'] == null
            ? null
            : Links.fromJson(data['_links'] as Map<String, dynamic>),
      );

  /// Converts the [GitHubFile] instance to a JSON map.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'path': path,
        'sha': sha,
        'size': size,
        'url': url,
        'html_url': htmlUrl,
        'git_url': gitUrl,
        'download_url': downloadUrl,
        'type': type,
        '_links': links?.toJson(),
      };

  /// The name of the file.
  final String name;

  /// The path of the file.
  final String path;

  /// The SHA value of the file.
  final String sha;

  /// The size of the file in bytes.
  final int size;

  /// The URL of the file.
  final String? url;

  /// The HTML URL of the file.
  final String? htmlUrl;

  /// The Git URL of the file.
  final String? gitUrl;

  /// The download URL of the file.
  final String downloadUrl;

  /// The type of the file.
  final String type;

  /// The links associated with the file.
  final Links? links;
}

/// Represents the links associated with a GitHub file resource.
class Links {
  /// Creates a new instance of the [Links] class.
  const Links({this.self, this.git, this.html});

  /// Creates a new instance of the [Links] class from a JSON map.
  factory Links.fromJson(Map<String, dynamic> data) => Links(
        self: data['self'] as String?,
        git: data['git'] as String?,
        html: data['html'] as String?,
      );

  /// Converts the [Links] instance to a JSON map.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'self': self,
        'git': git,
        'html': html,
      };

  /// The self link.
  final String? self;

  /// The git link.
  final String? git;

  /// The HTML link.
  final String? html;
}

/// Represents the result of an operation.
class Result {
  /// Creates a [Result] object with the specified success status and optional error message.
  const Result({
    required this.success,
    this.error,
  });

  /// Creates a [Result] object indicating a successful operation.
  factory Result.success() => const Result(success: true);

  /// Creates a [Result] object indicating a failed operation with the specified error message.
  factory Result.error(String error) => Result(success: false, error: error);

  /// Indicates whether the operation was successful.
  final bool success;

  /// The error message associated with a failed operation, or null if the operation was successful.
  final String? error;
}

/// Represents a build progress message.
class BuildProgressMessage {
  /// Creates a new instance of [BuildProgressMessage].
  ///
  /// The [message] parameter represents the message of the progress.
  /// The [progress] parameter represents the progress value.
  /// The [success] parameter indicates whether the progress was successful or not.
  /// The [finished] parameter indicates whether the progress is finished.
  const BuildProgressMessage({
    required this.message,
    required this.progress,
    required this.success,
    this.finished = false,
  });

  /// The message of the progress.
  final String message;

  /// Indicates whether the progress was successful or not.
  final bool success;

  /// The progress value (percentage).
  final double progress;

  /// Indicates whether the progress is finished.
  final bool finished;
}

/// Enum representing the events that can occur during a GitHub download.
enum GitHubDownloadEvent {
  /// The download was successful.
  downloaded,

  /// The download was skipped.
  skipped,

  /// The download failed.
  failed,
}

/// Represents an event for downloading a GitHub file.
///
/// This event contains information about the download event and the local path where the file will be saved.
/// Represents an event for downloading a GitHub file.
class GitHubFileDownloadEvent {
  /// Creates a new [GitHubFileDownloadEvent] with the specified [event] and [localPath].
  GitHubFileDownloadEvent({
    required this.event,
    required this.localPath,
  });

  /// The download event.
  final GitHubDownloadEvent event;

  /// The local path where the file will be saved.
  final String localPath;
}

// Helper functions

/// Creates folders based on the provided list of folder paths.
///
/// If a folder path includes a file extension, the parent directory of the file
/// will be used instead. The function creates the folders if they don't already exist.
///
/// Example:
/// ```dart
/// List<String> folders = ['/path/to/folder1', '/path/to/folder2/file.txt'];
/// createFolders(folders);
/// ```
void createFolders(List<String> folders) {
  for (String folder in folders) {
    if (path.extension(folder).isNotEmpty) {
      folder = path.dirname(folder);
    }

    final Directory dir = Directory(folder);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
  }
}

/// Calculates the SHA-1 hash value of a file.
///
/// Reads the contents of the file at the given [filePath] and calculates
/// the SHA-1 hash value using the `sha1` algorithm. Returns the hash value
/// as a string.
///
/// Throws an exception if the file cannot be read or if an error occurs
/// during the hashing process.
Future<String> calculateFileSha1(String filePath) async {
  final Uint8List bytes = await File(filePath).readAsBytes();
  final Digest digest = sha1.convert(bytes);
  return digest.toString();
}

/// Calculates the SHA-1 hash of a list of bytes.
///
/// Takes a [bytes] parameter, which is a list of integers representing the bytes.
/// Returns the SHA-1 hash as a string.
String calculateBlobSha1(List<int> bytes) {
  final Digest digest = sha1.convert(bytes);
  return digest.toString();
}

/// Calculates the SHA1 hash of a file located at the given [filePath].
///
/// The function reads the file as bytes, encodes it as a blob, and then calculates
/// the SHA1 hash of the blob. The resulting hash is returned as a string.
String calculateGithubSha1(String filePath) {
  final Uint8List bytes = File(filePath).readAsBytesSync();
  final List<int> blob =
      utf8.encode('blob ${bytes.length}${String.fromCharCode(0)}') + bytes;
  final String digest = calculateBlobSha1(blob);
  return digest;
}

/// A class that handles downloading files from a GitHub repository.
class GitHubFileDownloader {
  /// The [GitHubFileDownloader] class requires the [repoApiUrl] and [repoContentUrl]
  /// parameters to be provided during initialization. These parameters specify the
  /// API URL and content URL of the GitHub repository from which files will be downloaded.
  GitHubFileDownloader({
    required this.repoApiUrl,
    required this.repoContentUrl,
    this.sendPort,
  });

  final String repoApiUrl;
  final String repoContentUrl;
  final SendPort? sendPort;

  int _totalFiles = 0;
  int _downloadedFiles = 0;
  int _skippedFiles = 0;

  double get progress =>
      ((_downloadedFiles + _skippedFiles) / _totalFiles) * 100;
  String get progressMessage => 'Progress: ${progress.toStringAsFixed(2)}%';
  String get downloadStats =>
      'Downloaded $_downloadedFiles files, skipped $_skippedFiles files';

  Future<void> download(
    String repoCommit,
    Map<String, String> mappedFiles,
    Map<String, String> mappedFolders,
  ) async {
    await downloadMappedFiles(repoCommit, mappedFiles);
    await downloadMappedFolders(repoCommit, mappedFolders);
  }

  /// Retrieves the latest commit hash for a given branch from the repository API.
  ///
  /// The [branch] parameter specifies the branch name for which to retrieve the latest commit hash.
  /// By default, it is set to 'master'.
  ///
  /// Returns a [Future] that completes with a [String] representing the latest commit hash.
  Future<String> getLatestCommitHash({
    String branch = 'master',
  }) async {
    final String apiUrl = '$repoApiUrl/commits/$branch';
    final http.Response response = await http.get(Uri.parse(apiUrl));
    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;
    return data['sha'] as String;
  }

  /// Downloads and saves multiple files from a remote repository.
  ///
  /// The [repoCommit] parameter specifies the commit hash of the repository.
  /// The [mappedFiles] parameter is a map where the keys represent the local paths
  /// where the files will be saved, and the values represent the relative paths
  /// of the files in the repository.
  ///
  /// This method creates the necessary folders for the local paths and then
  /// iterates over each entry in the [mappedFiles] map. For each entry, it
  /// retrieves the file content from the remote repository using the provided
  /// commit hash and relative path, and saves it to the corresponding local path.
  ///
  /// Throws an exception if any error occurs during the download or file saving process.
  Future<void> downloadMappedFiles(
    String repoCommit,
    Map<String, String> mappedFiles,
  ) async {
    _totalFiles += mappedFiles.length;

    createFolders(mappedFiles.keys.toList());
    for (final MapEntry<String, String> entry in mappedFiles.entries) {
      final String localPath = entry.key;
      final Uri fileContentUrl =
          Uri.parse('$repoContentUrl/$repoCommit/${entry.value}');
      final http.Response fileContent = await http.get(fileContentUrl);
      await File(localPath).writeAsString(fileContent.body);

      _downloadedFiles++;
      sendPort?.send(
        BuildProgressMessage(
          message: 'Downloading file: $localPath',
          progress: progress,
          success: true,
        ),
      );
    }
  }

  /// Downloads the mapped folders from a GitHub repository at a specific commit.
  ///
  /// The [repoCommit] parameter specifies the commit hash of the repository.
  /// The [mappedFolders] parameter is a map where the keys represent the local paths
  /// where the files will be downloaded, and the values represent the corresponding
  /// paths in the GitHub repository.
  /// The [timeout] parameter specifies the maximum duration for the download operation.
  ///
  /// This method iterates over each entry in the [mappedFolders] map and creates the
  /// necessary local folders. Then, it retrieves the list of files in the GitHub
  /// repository at the specified [repoPath] and [repoCommit]. For each file, it
  /// initiates a download using the [downloadFile] method. The downloads are executed
  /// concurrently using [Future.wait].
  ///
  /// Throws an exception if any of the download operations fail.
  Future<void> downloadMappedFolders(
    String repoCommit,
    Map<String, String> mappedFolders, {
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final Map<String, List<GitHubFile>> folderContents =
        await _getMappedFolderContents(mappedFolders, repoCommit);

    for (final MapEntry<String, List<GitHubFile>> entry
        in folderContents.entries) {
      await _downloadFolderContents(entry.key, entry.value);
    }

    sendPort?.send(
      const BuildProgressMessage(
        message: '\nDownloaded all files',
        progress: 100,
        success: true,
        finished: true,
      ),
    );
  }

  Future<void> _downloadFolderContents(
    String key,
    List<GitHubFile> value,
  ) async {
    await for (final GitHubFileDownloadEvent event
        in downloadFiles(value, key)) {
      switch (event.event) {
        case GitHubDownloadEvent.downloaded:
          _downloadedFiles++;
          sendProgressMessage(
            'Downloading file: ${event.localPath}',
            success: true,
          );
        case GitHubDownloadEvent.skipped:
          _skippedFiles++;
          sendProgressMessage(
            'Skipped file: ${event.localPath}',
            success: true,
          );
        case GitHubDownloadEvent.failed:
          sendProgressMessage(
            'Failed to download file: ${event.localPath}',
          );
      }
    }
  }

  Future<Map<String, List<GitHubFile>>> _getMappedFolderContents(
    Map<String, String> mappedFolders,
    String repoCommit,
  ) async {
    final Map<String, List<GitHubFile>> folderContents = {};

    for (final MapEntry<String, String> entry in mappedFolders.entries) {
      createFolders(mappedFolders.keys.toList());
      final String localPath = entry.key;
      final String repoPath = entry.value;
      final List<GitHubFile> coins =
          await getGitHubDirectoryContents(repoPath, repoCommit);

      _totalFiles += coins.length;
      folderContents[localPath] = coins;
    }
    return folderContents;
  }

  /// Retrieves the contents of a GitHub directory for a given repository and commit.
  ///
  /// The [repoPath] parameter specifies the path of the directory within the repository.
  /// The [repoCommit] parameter specifies the commit hash or branch name.
  ///
  /// Returns a [Future] that completes with a list of [GitHubFile] objects representing the files in the directory.
  Future<List<GitHubFile>> getGitHubDirectoryContents(
    String repoPath,
    String repoCommit,
  ) async {
    final Map<String, String> headers = <String, String>{
      'Accept': 'application/vnd.github.v3+json',
    };
    final String apiUrl = '$repoApiUrl/contents/$repoPath?ref=$repoCommit';

    final http.Request req = http.Request('GET', Uri.parse(apiUrl));
    req.headers.addAll(headers);
    final http.StreamedResponse response = await http.Client().send(req);
    final String respString = await response.stream.bytesToString();
    final List<dynamic> data = jsonDecode(respString) as List<dynamic>;

    return data
        .where(
          (dynamic item) => (item as Map<String, dynamic>)['type'] == 'file',
        )
        .map(
          (dynamic file) => GitHubFile.fromJson(file as Map<String, dynamic>),
        )
        .toList();
  }

  /// Sends a progress message to the specified [sendPort].
  ///
  /// The [message] parameter is the content of the progress message.
  /// The [success] parameter indicates whether the progress was successful or not.
  void sendProgressMessage(String message, {bool success = false}) {
    sendPort?.send(
      BuildProgressMessage(
        message: message,
        progress: progress,
        success: success,
      ),
    );
  }

  /// Downloads a file from GitHub.
  ///
  /// This method takes a [GitHubFile] object and a [localDir] path as input,
  /// and downloads the file to the specified local directory.
  ///
  /// If the file already exists locally and has the same SHA as the GitHub file,
  /// the download is skipped and a [GitHubFileDownloadEvent] with the event type
  /// [GitHubDownloadEvent.skipped] is returned.
  ///
  /// If the file does not exist locally or has a different SHA, the file is downloaded
  /// from the GitHub URL specified in the [GitHubFile] object. The downloaded file
  /// is saved to the local directory and a [GitHubFileDownloadEvent] with the event type
  /// [GitHubDownloadEvent.downloaded] is returned.
  ///
  /// If an error occurs during the download process, an exception is thrown.
  ///
  /// Returns a [GitHubFileDownloadEvent] object containing the event type and the
  /// local path of the downloaded file.
  static Future<GitHubFileDownloadEvent> downloadFile(
    GitHubFile item,
    String localDir,
  ) async {
    final String coinName = path.basenameWithoutExtension(item.name);
    final String outputPath = path.join(localDir, item.name);

    final File localFile = File(outputPath);
    if (localFile.existsSync()) {
      final String localFileSha = calculateGithubSha1(outputPath);
      if (localFileSha == item.sha) {
        return GitHubFileDownloadEvent(
          event: GitHubDownloadEvent.skipped,
          localPath: outputPath,
        );
      }
    }

    try {
      final String fileResponse = await http.read(Uri.parse(item.downloadUrl));
      await File(outputPath).writeAsBytes(fileResponse.codeUnits);
      return GitHubFileDownloadEvent(
        event: GitHubDownloadEvent.downloaded,
        localPath: outputPath,
      );
    } catch (e) {
      print('Failed to download icon for $coinName: $e');
      rethrow;
    }
  }

  /// Downloads multiple files from GitHub and yields download events.
  ///
  /// Given a list of [files] and a [localDir], this method downloads each file
  /// and yields a [GitHubFileDownloadEvent] for each file. The [GitHubFileDownloadEvent]
  /// contains information about the download event, such as whether the file was
  /// successfully downloaded or skipped, and the [localPath] where the file was saved.
  ///
  /// Example usage:
  /// ```dart
  /// List<GitHubFile> files = [...];
  /// String localDir = '/path/to/local/directory';
  /// Stream<GitHubFileDownloadEvent> downloadStream = downloadFiles(files, localDir);
  /// await for (GitHubFileDownloadEvent event in downloadStream) {
  /// }
  /// ```
  static Stream<GitHubFileDownloadEvent> downloadFiles(
    List<GitHubFile> files,
    String localDir,
  ) async* {
    for (final GitHubFile file in files) {
      yield await downloadFile(file, localDir);
    }
  }

  /// Reverts the changes made to a Git file at the specified [filePath].
  /// Returns `true` if the changes were successfully reverted, `false` otherwise.
  static Future<bool> revertChangesToGitFile(String filePath) async {
    final ProcessResult result =
        await Process.run('git', <String>['checkout', filePath]);

    if (result.exitCode != 0) {
      print('Failed to revert changes to $filePath');
      return false;
    } else {
      print('Reverted changes to $filePath');
      return true;
    }
  }

  /// Reverts changes made to a Git file or deletes it if it exists.
  ///
  /// This method takes a [filePath] as input and reverts any changes made to the Git file located at that path.
  /// If the file does not exist or the revert operation fails, the file is deleted.
  ///
  /// Example usage:
  /// ```dart
  /// await revertOrDeleteGitFile('/Users/francois/Repos/komodo/komodo-wallet-archive/app_build/fetch_coin_assets.dart');
  /// ```
  static Future<void> revertOrDeleteGitFile(String filePath) async {
    final bool result = await revertChangesToGitFile(filePath);
    if (!result && File(filePath).existsSync()) {
      print('Deleting $filePath');
      await File(filePath).delete();
    }
  }

  /// Reverts or deletes the specified git files.
  ///
  /// This method takes a list of file paths and iterates over each path,
  /// calling the [revertOrDeleteGitFile] method to revert or delete the file.
  ///
  /// Example usage:
  /// ```dart
  /// List<String> filePaths = ['/path/to/file1', '/path/to/file2'];
  /// await revertOrDeleteGitFiles(filePaths);
  /// ```
  static Future<void> revertOrDeleteGitFiles(List<String> filePaths) async {
    for (final String filePath in filePaths) {
      await revertOrDeleteGitFile(filePath);
    }
  }
}
