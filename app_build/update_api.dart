// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:html/parser.dart' as parser;
import 'package:archive/archive_io.dart';

import 'build_steps.dart';

class UpdateAPIStep extends BuildStep {
  final String projectRoot;
  late Map<String, dynamic> config;
  late String apiVersion;
  late Map<String, dynamic> platformsConfig;
  late String baseUrl;
  late String apiBranch;
  String? selectedPlatform;
  bool forceUpdate = false;

  UpdateAPIStep(this.projectRoot) {
    _loadConfig();
    _loadArguments();
  }

  @override
  Future<void> build() async {
    if (!config['api']['should_update']) {
      print('API update is not enabled in the configuration.');
      return;
    }
    try {
      await updateAPI();
    } catch (e) {
      print('Error updating API: $e');
    }
  }

  @override
  bool canSkip() {
    // TODO: Add skip logic
    return false;
  }

  @override
  Future<void> revert() async {
    print('Reverting changes made by UpdateAPIStep...');
    // TODO: Add revert logic
  }

  void _loadConfig() {
    final configFile = File('$projectRoot/app_build/build_config.json');
    config = json.decode(configFile.readAsStringSync());
    apiVersion = config['api']['version'];
    platformsConfig = config['api']['platforms'];
    baseUrl = config['api']['base_url'];
    apiBranch = config['api']['default_branch'];
  }

  void _loadArguments() {
    final args = config['api']['arguments'];
    if (args != null) {
      selectedPlatform = args['platform'];
      forceUpdate = args['force'] ?? false;
    }
  }

  Future<void> updateAPI() async {
    if (config['api']['should_update']) {
      Iterable<String> platformsToUpdate;
      if (selectedPlatform != null &&
          platformsConfig.containsKey(selectedPlatform)) {
        platformsToUpdate = [selectedPlatform!];
      } else {
        platformsToUpdate = platformsConfig.keys;
      }

      for (final platform in platformsToUpdate) {
        await _updatePlatform(platform);
      }
      _updateDocumentation();
    } else {
      print('API update is not enabled in the configuration.');
    }
  }

  Future<void> _updatePlatform(String platform) async {
    print('Updating $platform platform...');
    final destinationFolder = _getPlatformDestinationFolder(platform);
    final isOutdated = await _checkIfOutdated(platform, destinationFolder);

    if (forceUpdate || isOutdated) {
      final zipFileUrl = await _findZipFileUrl(platform);
      await _downloadAndExtract(zipFileUrl, destinationFolder, platform);
      _updateLastUpdatedFile(platform, destinationFolder);
      print('$platform platform update completed.');
    } else {
      print('$platform platform is up to date.');
    }
  }

  Future<bool> _checkIfOutdated(
      String platform, String destinationFolder) async {
    final lastUpdatedFilePath =
        path.join(destinationFolder, '.api_last_updated');
    final lastUpdatedFile = File(lastUpdatedFilePath);

    if (!lastUpdatedFile.existsSync()) {
      return true;
    }

    try {
      final lastUpdatedData = json.decode(lastUpdatedFile.readAsStringSync());
      if (lastUpdatedData['version'] == apiVersion) {
        print("version: $apiVersion");
        return false;
      }
    } catch (e) {
      print('Error reading or parsing .api_last_updated: $e');
    }

    return true;
  }

  Future<void> _updateWebPlatform() async {
    print('Updating Web platform...');
    final installResult =
        await Process.run('npm', ['install'], workingDirectory: projectRoot);
    if (installResult.exitCode != 0) {
      throw Exception('npm install failed: ${installResult.stderr}');
    }

    final buildResult = await Process.run('npm', ['run', 'build'],
        workingDirectory: projectRoot);
    if (buildResult.exitCode != 0) {
      throw Exception('npm run build failed: ${buildResult.stderr}');
    }

    print('Web platform updated successfully.');
  }

  Future<void> _updateLinuxPlatform(String destinationFolder) async {
    print('Updating Linux platform...');
    final mm2FilePath = path.join(destinationFolder, 'mm2');
    await Process.run('chmod', ['+x', mm2FilePath]);
    print('Linux platform updated successfully.');
  }

  String _getPlatformDestinationFolder(String platform) {
    if (platformsConfig.containsKey(platform)) {
      return path.join(projectRoot, platformsConfig[platform]['path']);
    } else {
      throw ArgumentError('Invalid platform: $platform');
    }
  }

  Future<String> _findZipFileUrl(String platform) async {
    final url = '$baseUrl/$apiBranch/';
    final response = await http.get(Uri.parse(url));
    _checkResponseSuccess(response);

    final document = parser.parse(response.body);
    final searchParameters = platformsConfig[platform];
    final keywords = searchParameters['keywords'];
    final extensions = ['.zip'];

    for (final element in document.querySelectorAll('a')) {
      final href = element.attributes['href'];
      if (href != null &&
          keywords.any((keyword) => href.contains(keyword)) &&
          extensions.any((extension) => href.endsWith(extension)) &&
          href.contains(apiVersion)) {
        return '$baseUrl/$apiBranch/$href';
      }
    }

    throw Exception('Zip file not found for platform $platform');
  }

  void _checkResponseSuccess(http.Response response) {
    if (response.statusCode != 200) {
      throw HttpException(
          'Failed to fetch data: ${response.statusCode} ${response.reasonPhrase}');
    }
  }

  Future<void> _downloadAndExtract(
      String url, String destinationFolder, String platform) async {
    print('Downloading $url...');
    final response = await http.get(Uri.parse(url));
    _checkResponseSuccess(response);

    final zipFileName = path.basename(url);
    final zipFilePath = path.join(destinationFolder, zipFileName);

    // Ensure the destination folder exists
    final directory = Directory(destinationFolder);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final zipFile = File(zipFilePath);
    try {
      await zipFile.writeAsBytes(response.bodyBytes);
    } catch (e) {
      print('Error writing file: $e');
      rethrow;
    }

    print('Downloaded $zipFileName');

    await _extractZipFile(zipFilePath, destinationFolder);
    zipFile.deleteSync();

    if (platform == 'web') {
      await _updateWebPlatform();
    } else if (platform == 'linux') {
      await _updateLinuxPlatform(destinationFolder);
    }
  }

  Future<void> _extractZipFile(
      String zipFilePath, String destinationFolder) async {
    final bytes = File(zipFilePath).readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(bytes);

    for (final file in archive) {
      final filename = file.name;
      if (file.isFile) {
        final data = file.content as List<int>;
        File(path.join(destinationFolder, filename))
          ..createSync(recursive: true)
          ..writeAsBytesSync(data);
      } else {
        Directory(path.join(destinationFolder, filename))
            .create(recursive: true);
      }
    }
    print('Extraction completed.');
  }

  void _updateLastUpdatedFile(String platform, String destinationFolder) {
    final lastUpdatedFile =
        File(path.join(destinationFolder, '.api_last_updated'));
    final currentTimestamp = DateTime.now().toIso8601String();
    lastUpdatedFile.writeAsStringSync(
        json.encode({'version': apiVersion, 'timestamp': currentTimestamp}));
    print('Updated last updated file for $platform.');
  }

  void _updateDocumentation() {
    final documentationFile = File('$projectRoot/docs/UPDATE_API_MODULE.md');
    final content = documentationFile.readAsStringSync().replaceAllMapped(
          RegExp(r'(Current api module version is) `([^`]+)`'),
          (match) => '${match[1]} `$apiVersion`',
        );
    documentationFile.writeAsStringSync(content);
    print('Updated API version in documentation.');
  }
}
