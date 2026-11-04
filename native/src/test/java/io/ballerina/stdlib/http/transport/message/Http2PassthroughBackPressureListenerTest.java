/*
 * Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.stdlib.http.transport.message;

import org.mockito.ArgumentCaptor;
import org.testng.annotations.Test;

import java.util.List;
import java.util.function.BooleanSupplier;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.testng.Assert.assertFalse;
import static org.testng.Assert.assertTrue;

/**
 * Verifies that {@link Http2PassthroughBackPressureListener} hands the inbound event loop the latest decision rather
 * than a fixed action, so a resume queued earlier cannot undo a later pause.
 */
public class Http2PassthroughBackPressureListenerTest {

    @Test
    public void testQueuedChangeAppliesTheLatestDecision() {
        Http2InboundContentListener inbound = mock(Http2InboundContentListener.class);
        Http2PassthroughBackPressureListener listener = new Http2PassthroughBackPressureListener(inbound);

        listener.onUnWritable();
        listener.onWritable();
        listener.onUnWritable();

        ArgumentCaptor<BooleanSupplier> decisions = ArgumentCaptor.forClass(BooleanSupplier.class);
        verify(inbound, times(3)).applyByteConsumption(decisions.capture());
        List<BooleanSupplier> queued = decisions.getAllValues();
        assertTrue(queued.get(1).getAsBoolean(), "The resume queued before the last pause would resume consumption");
        listener.onWritable();
        assertFalse(queued.get(2).getAsBoolean());
    }

    @Test
    public void testWritableWithoutPauseDoesNothing() {
        Http2InboundContentListener inbound = mock(Http2InboundContentListener.class);
        Http2PassthroughBackPressureListener listener = new Http2PassthroughBackPressureListener(inbound);

        listener.onWritable();

        verify(inbound, never()).applyByteConsumption(org.mockito.ArgumentMatchers.any());
    }
}
