//*****************************************************************************
// MIT License
//
// Copyright (c) 2024 Alain Duron <duron.alain@gmail.com>
// Copyright (c) 2024 Quentin Quadrat <lecrapouille@gmail.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//*****************************************************************************

#include "ad_blocker.hpp"
#include "helper_log.hpp"

//------------------------------------------------------------------------------
AdBlocker::AdBlocker()
{
    GDCEF_DEBUG("");

    const std::vector<std::string> default_patterns = {
        // Classic advertising networks
        R"(.*doubleclick\.net.*)",
        R"(.*googlesyndication\.com.*)",
        R"(.*google-analytics\.com.*)",
        R"(.*adnxs\.com.*)",
        R"(.*advertising\.com.*)",
        R"(.*quantserve\.com.*)",
        R"(.*scorecardresearch\.com.*)",
        R"(.*zedo\.com.*)",
        R"(.*adbrite\.com.*)",
        R"(.*adocean\.pl.*)",
        R"(.*adsonar\.com.*)",
        R"(.*adtech\..*)",
        R"(.*adtechus\.com.*)",
        R"(.*atwola\.com.*)",
        R"(.*bidvertiser\.com.*)",
        R"(.*casalemedia\.com.*)",
        R"(.*chitika\.net.*)",
        R"(.*clicksor\.com.*)",
        R"(.*eclick\.vn.*)",
        R"(.*fmpub\.net.*)",
        R"(.*openx\..*)",
        R"(.*rubiconproject\.com.*)",
        R"(.*taboola\.com.*)",
        R"(.*outbrain\.com.*)",
        R"(.*criteo\..*)",
        R"(.*amazon-adsystem\.com.*)",
        R"(.*adform\..*)",
        R"(.*admob\..*)",
        R"(.*moatads\.com.*)",

        // Trackers et analytics
        R"(.*analytics\..*)",
        R"(.*tracking\..*)",
        R"(.*track\..*)",
        R"(.*stats\..*)",
        R"(.*pixel\..*)",
        R"(.*log\..*)",
        R"(.*beacon\..*)",
        R"(.*telemetry\..*)",
        R"(.*metrics\..*)",
        R"(.*matomo\..*)",
        R"(.*piwik\..*)",

        // Generic patterns
        R"(.*/ads/.*)",
        R"(.*/adserv.*)",
        R"(.*/banner.*)",
        // R"(.*/pop.*)", // See https://github.com/Lecrapouille/gdcef/issues/80
        R"(.*/sponsor.*)",
        R"(.*/advertising.*)",
        R"(.*/advert.*)",
        R"(.*/clicktrack.*)",
        R"(.*/affiliate.*)",
        R"(.*/promo.*)",
        R"(.*/commercials.*)",
        R"(.*/banners.*)",
        R"(.*/analytics.*)",
        R"(.*/tracker.*)",
        R"(.*/pixels.*)",
        R"(.*/count.*)",
        // R"(.*/stat.*)", // See
        // https://github.com/Lecrapouille/gdcef/issues/80
        R"(.*/targeting.*)",
        R"(.*/adview.*)",
        R"(.*/adclick.*)",

        // Social networks tracking
        R"(.*facebook\.com/tr.*)",
        R"(.*facebook\.com/plugins.*)",
        R"(.*linkedin\.com/pixel.*)",
        R"(.*twitter\.com/i/jot.*)",
        R"(.*pinterest\.com/ping.*)",

        // Other specific trackers
        R"(.*hotjar\.com.*)",
        R"(.*mouseflow\.com.*)",
        R"(.*crazyegg\.com.*)",
        R"(.*clicktale\.net.*)",
        R"(.*optimizely\.com.*)",
        R"(.*mixpanel\.com.*)",
        R"(.*kissmetrics\.com.*)",
        R"(.*segment\.io.*)",
        R"(.*segment\.com.*)",
        R"(.*amplitude\.com.*)",
        R"(.*bugsnag\.com.*)",
        R"(.*sentry\.io.*)",
        R"(.*newrelic\.com.*)"};

    for (const auto& pattern : default_patterns)
    {
        addPattern(pattern);
    }
}

//------------------------------------------------------------------------------
void AdBlocker::enable(bool enable)
{
    m_enabled = enable;
}

//------------------------------------------------------------------------------
bool AdBlocker::addPattern(const std::string& pattern)
{
    GDCEF_DEBUG("Adding ad blocking pattern: " << pattern);
    try
    {
        m_patterns.push_back(std::regex(pattern, std::regex::icase));
        return true;
    }
    catch (const std::regex_error& e)
    {
        GDCEF_ERROR("Invalid ad blocking pattern: " << pattern);
        return false;
    }
}

//------------------------------------------------------------------------------
CefResourceRequestHandler::ReturnValue
AdBlocker::OnBeforeResourceLoad(CefRefPtr<CefBrowser> browser,
                                CefRefPtr<CefFrame> frame,
                                CefRefPtr<CefRequest> request,
                                CefRefPtr<CefCallback> callback)
{
    std::string url = request->GetURL().ToString();
    if (m_enabled)
    {
        for (const auto& pattern : m_patterns)
        {
            if (std::regex_match(url, pattern))
            {
                GDCEF_DEBUG("Blocked ad URL: " << url);
                return RV_CANCEL; // Block the request
            }
        }
    }

    // GDCEF_DEBUG("Allowed ad URL: " << url);
    return RV_CONTINUE; // Allow the request
}