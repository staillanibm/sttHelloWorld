package sttHelloWorld.eu.sttlab.services;

// -----( IS Java Code Template v1.2

import com.wm.data.*;
import com.wm.util.Values;
import com.wm.app.b2b.server.Service;
import com.wm.app.b2b.server.ServiceException;
// --- <<IS-START-IMPORTS>> ---
// --- <<IS-END-IMPORTS>> ---

public final class java

{
	// ---( internal utility methods )---

	final static java _instance = new java();

	static java _newInstance() { return new java(); }

	static java _cast(Object o) { return (java)o; }

	// ---( server methods )---




	public static final void calculateFibo (IData pipeline)
        throws ServiceException
	{
		// --- <<IS-START(calculateFibo)>> ---
		// @sigtype java 3.5
		// [i] field:0:required n
		// [o] field:0:required result
		IDataCursor pipelineCursor = pipeline.getCursor();
		int	n = Integer.parseInt(IDataUtil.getString( pipelineCursor, "n" ));
		pipelineCursor.destroy();
		
		int a = 0;
		int b = n;
		if (n > 1) {
			b = 1;
			for (int i = 2; i <= n; i++) {
			    int next = a + b;
			    a = b;
			    b = next;
			}
		}
		
		// pipeline
		IDataCursor pipelineCursor_1 = pipeline.getCursor();
		IDataUtil.put( pipelineCursor_1, "result", Integer.toString(b) );
		pipelineCursor_1.destroy();
		// --- <<IS-END>> ---

                
	}
}

