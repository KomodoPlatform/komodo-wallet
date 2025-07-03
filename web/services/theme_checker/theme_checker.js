(() => {
    let themeIndex = +localStorage.getItem('flutter.themeMode');
    themeIndex = themeIndex === 0 ? 2 : themeIndex;
    if (themeIndex === 2) {
        const loading = document.querySelector('.loading');
        if (loading != null) { loading.classList.add('loading_dark'); }
    }
    const lightBackgroundColor = '#f5f5f5';
    const darkBackgroundColor = '#121420';
    const ultraDarkBackgroundColor = '#000000';
    const headTag = document.querySelector('head');
    const lightThemeColorMetaTag = document.createElement('meta');
    lightThemeColorMetaTag.setAttribute('media', '(prefers-color-scheme: light)');
    lightThemeColorMetaTag.setAttribute('name', 'theme-color');
    const darkThemeColorMetaTag = document.createElement('meta');
    darkThemeColorMetaTag.setAttribute('media', '(prefers-color-scheme: dark)');
    darkThemeColorMetaTag.setAttribute('name', 'theme-color');

    if (themeIndex === 1) {
        lightThemeColorMetaTag.setAttribute('content', lightBackgroundColor);
        darkThemeColorMetaTag.setAttribute('content', lightBackgroundColor);
    } else if (themeIndex === 2) {
        lightThemeColorMetaTag.setAttribute('content', darkBackgroundColor);
        darkThemeColorMetaTag.setAttribute('content', darkBackgroundColor);
    } else if (themeIndex === 3) {
        lightThemeColorMetaTag.setAttribute('content', ultraDarkBackgroundColor);
        darkThemeColorMetaTag.setAttribute('content', ultraDarkBackgroundColor);
    }
    headTag.appendChild(lightThemeColorMetaTag);
    headTag.appendChild(darkThemeColorMetaTag);
    window.changeTheme = (themeIndex) => {
        if (themeIndex === 1) {
            lightThemeColorMetaTag.setAttribute('content', lightBackgroundColor);
            darkThemeColorMetaTag.setAttribute('content', lightBackgroundColor);
        } else if (themeIndex === 2) {
            lightThemeColorMetaTag.setAttribute('content', darkBackgroundColor);
            darkThemeColorMetaTag.setAttribute('content', darkBackgroundColor);
        } else if (themeIndex === 3) {
            lightThemeColorMetaTag.setAttribute('content', ultraDarkBackgroundColor);
            darkThemeColorMetaTag.setAttribute('content', ultraDarkBackgroundColor);
        }
    }
})();