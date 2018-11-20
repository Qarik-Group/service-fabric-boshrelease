namespace SmokeTestCSharpClient
{
    using System;
    using Microsoft.ServiceFabric.Actors;
    using Microsoft.ServiceFabric.Actors.Client;
    using SmokeTestCSharp.Interfaces;

    class Program
    {
        static void Main(string[] args)
        {
            var SmokeTestCSharpTestClient = ActorProxy.Create<ISmokeTestCSharp>(new ActorId(0x100), "fabric:/SmokeTestCSharp" , "SmokeTestCSharp");
            int result = SmokeTestCSharpTestClient.GetCountAsync().Result;
            SmokeTestCSharpTestClient.SetCountAsync(result + 1).Wait();
            Console.WriteLine("Value = {0}", result);
        }
    }
}
