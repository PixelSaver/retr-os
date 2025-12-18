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

#ifndef AD_BLOCKER_HPP
#define AD_BLOCKER_HPP

#include "cef_resource_request_handler.h"
#include <regex>
#include <string>
#include <vector>

//! \brief Simple ad blocker based on URL pattern matching
class AdBlocker: public CefResourceRequestHandler
{
public:

    //! \brief Constructor loading default ad patterns
    AdBlocker();

    //! \brief Enable or disable the ad blocker
    void enable(bool enable);

    //! \brief Check if the ad blocker is enabled
    inline bool is_enabled() const
    {
        return m_enabled;
    }

    //! \brief Add a custom pattern to block
    //! \param[in] pattern Regex pattern to match URLs to block
    //! \return true if the pattern is valid, false otherwise
    bool addPattern(const std::string& pattern);

    //! \brief CEF callback to handle resource requests
    //! \return CEF_RESPONSE_FILTER_RESPONSE to block the request
    virtual CefResourceRequestHandler::ReturnValue
    OnBeforeResourceLoad(CefRefPtr<CefBrowser> browser,
                         CefRefPtr<CefFrame> frame,
                         CefRefPtr<CefRequest> request,
                         CefRefPtr<CefCallback> callback) override;

    //! \brief CEF reference counting
    IMPLEMENT_REFCOUNTING(AdBlocker);

private:

    //! \brief Patterns to block
    std::vector<std::regex> m_patterns;

    //! \brief Enable or disable the ad blocker
    bool m_enabled = true;
};

#endif
