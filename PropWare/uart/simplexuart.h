/**
 * @file        PropWare/uart/simplexuart.h
 *
 * @author      David Zemon
 *
 * @copyright
 * The MIT License (MIT)<br>
 * <br>Copyright (c) 2013 David Zemon<br>
 * <br>Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:<br>
 * <br>The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.<br>
 * <br>THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#pragma once

#include <PropWare/uart/abstractsimplexuart.h>

namespace PropWare {

/**
 * @brief   An easy-to-use class for simplex (transmit only) UART communication
 */
class SimplexUART : public AbstractSimplexUART {
    public:
        /**
         * @brief   No-arg constructors are helpful when avoiding dynamic
         *          allocation
         */
        SimplexUART () :
                AbstractSimplexUART() {
        }

        /**
         * @brief       Construct a UART instance capable of simplex serial
         *              communications
         *
         * @param[in]   tx  Bit mask used for the TX (transmit) pin
         */
        SimplexUART (const Port::Mask tx) :
                AbstractSimplexUART() {
            this->set_tx_mask(tx);
        }
};

}
